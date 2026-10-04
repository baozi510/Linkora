#include "analysis.h"
#include <memory>
#include <cstring>
#include <sys/stat.h>
extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libavcodec/codec_desc.h>
#include <libavutil/dovi_meta.h>
#include <libavutil/pixdesc.h>
#include <libswscale/swscale.h>
}

namespace linkora_ffmpeg {
namespace {
[[noreturn]] void Fail(const char *code, int native = 0) {
    char message[AV_ERROR_MAX_STRING_SIZE] = {};
    if (native < 0) av_strerror(native, message, sizeof(message));
    // av_strerror is bounded and contains no input locator, credentials or signed query.
    throw Failure{code, message};
}
void Check(RequestState &state) {
    const auto status = state.Poll();
    if (status == RequestStatus::Cancelled) Fail("FF_CANCELLED");
    if (status == RequestStatus::Timeout) Fail("FF_TIMEOUT");
}
int Interrupt(void *opaque) {
    const auto status = static_cast<RequestState *>(opaque)->Poll();
    return status == RequestStatus::Cancelled || status == RequestStatus::Timeout;
}
std::string Text(const char *value, size_t max = 128) { return value ? std::string(value, strnlen(value, max)) : ""; }
class Input {
public:
    AVFormatContext *context = nullptr;
    Input(const std::string &input, RequestState &state, int timeout) {
        Check(state);
        // FIFO/device opens cannot reliably be interrupted by the file protocol.
        if (input[0] == '/') {
            struct stat info {};
            if (stat(input.c_str(), &info) != 0) Fail("FF_OPEN_FAILED");
            if (!S_ISREG(info.st_mode)) Fail("FF_INVALID_INPUT");
        }
        context = avformat_alloc_context(); if (!context) Fail("FF_SIZE_REJECTED");
        context->interrupt_callback = {Interrupt, &state};
        context->max_streams = 64;
        // Self-contained containers only. No playlist/nested URL demuxers in this URL/path phase.
        context->format_whitelist = av_strdup("mov,matroska,avi,mpegts,mpeg,ogg,wav,flac,mp3");
        if (!context->format_whitelist) { avformat_close_input(&context); Fail("FF_SIZE_REJECTED"); }
        AVDictionary *options = nullptr;
        if (av_dict_set(&options, "protocol_whitelist", input[0] == '/' ? "file" : "http,tcp", 0) < 0 ||
            av_dict_set(&options, "http_proxy", "", 0) < 0 || av_dict_set(&options, "max_redirects", "0", 0) < 0 ||
            av_dict_set_int(&options, "rw_timeout", static_cast<int64_t>(timeout) * 1000, 0) < 0 ||
            av_dict_set_int(&options, "probesize", 5 * 1024 * 1024, 0) < 0 ||
            av_dict_set_int(&options, "analyzeduration", 5 * AV_TIME_BASE, 0) < 0) {
            av_dict_free(&options); avformat_close_input(&context); Fail("FF_SIZE_REJECTED");
        }
        int result = avformat_open_input(&context, input.c_str(), nullptr, &options);
        av_dict_free(&options);
        if (result < 0) { avformat_close_input(&context); Check(state); Fail("FF_OPEN_FAILED", result); }
        result = avformat_find_stream_info(context, nullptr);
        if (result < 0) { avformat_close_input(&context); Check(state); Fail("FF_STREAM_INFO_FAILED", result); }
        try { Check(state); } catch (...) { avformat_close_input(&context); throw; }
    }
    ~Input() { avformat_close_input(&context); }
};
class TagBudget {
public:
    std::string Read(AVDictionary *tags, const char *name) {
        const auto entry = av_dict_get(tags, name, nullptr, 0);
        return Take(entry ? entry->value : nullptr, 512);
    }
    std::string Take(const char *value, size_t max) {
        auto result = BoundedMetadataText(value, std::min(max, remaining));
        remaining -= result.size(); return result;
    }
    size_t remaining = 16384;
};
double Milliseconds(int64_t value, AVRational timeBase) {
    return value == AV_NOPTS_VALUE || value < 0 ? 0 : av_rescale_q(value, timeBase, AVRational{1, 1000});
}
void FreeCodec(AVCodecContext *value) { avcodec_free_context(&value); }
void FreeFrame(AVFrame *value) { av_frame_free(&value); }
void FreePacket(AVPacket *value) { av_packet_free(&value); }
}

Probe ProbeInput(const std::string &input, RequestState &state, int timeoutMs) {
    Input source(input, state, timeoutMs); auto *format = source.context;
    Probe result; TagBudget budget;
    result.container = Text(format->iformat->name);
    result.durationMs = Milliseconds(format->duration, AVRational{1, AV_TIME_BASE});
    result.bitrate = std::max<int64_t>(0, format->bit_rate);
    if (format->pb) result.sizeBytes = std::max<int64_t>(0, avio_size(format->pb));
    for (unsigned i = 0; i < std::min(format->nb_streams, 64u); ++i) {
        Check(state); auto *stream = format->streams[i]; auto *params = stream->codecpar;
        Stream track; track.index = stream->index; track.id = stream->id;
        track.codec = Text(avcodec_get_name(params->codec_id));
        track.profile = Text(avcodec_profile_name(params->codec_id, params->profile));
        track.bitrate = std::max<int64_t>(0, params->bit_rate);
        track.language = budget.Read(stream->metadata, "language"); track.title = budget.Read(stream->metadata, "title");
        track.isDefault = (stream->disposition & AV_DISPOSITION_DEFAULT) != 0;
        if (params->codec_type == AVMEDIA_TYPE_VIDEO) {
            track.level = std::max(0, params->level); track.width = params->width; track.height = params->height;
            const auto rate = av_guess_frame_rate(format, stream, nullptr); track.frameRate = rate.den > 0 ? av_q2d(rate) : 0;
            const auto pixel = static_cast<AVPixelFormat>(params->format); track.pixelFormat = Text(av_get_pix_fmt_name(pixel));
            const auto desc = av_pix_fmt_desc_get(pixel); track.bitDepth = params->bits_per_raw_sample;
            if (track.bitDepth <= 0 && desc) for (int c = 0; c < desc->nb_components; ++c) track.bitDepth = std::max(track.bitDepth, desc->comp[c].depth);
            track.colorPrimaries = Text(av_color_primaries_name(params->color_primaries));
            track.transfer = Text(av_color_transfer_name(params->color_trc)); track.colorSpace = Text(av_color_space_name(params->color_space));
            const auto dovi = av_packet_side_data_get(params->coded_side_data, params->nb_coded_side_data, AV_PKT_DATA_DOVI_CONF);
            if (dovi && dovi->size >= sizeof(AVDOVIDecoderConfigurationRecord)) {
                track.hasDolbyVisionConfiguration = true;
                track.dolbyVisionProfile = reinterpret_cast<const AVDOVIDecoderConfigurationRecord *>(dovi->data)->dv_profile;
            }
            result.video.push_back(std::move(track));
        } else if (params->codec_type == AVMEDIA_TYPE_AUDIO) {
            track.channels = params->ch_layout.nb_channels; track.sampleRate = params->sample_rate;
            char layout[128] = {}; av_channel_layout_describe(&params->ch_layout, layout, sizeof(layout)); track.channelLayout = layout;
            result.audio.push_back(std::move(track));
        } else if (params->codec_type == AVMEDIA_TYPE_SUBTITLE) {
            track.isForced = (stream->disposition & AV_DISPOSITION_FORCED) != 0;
            const auto desc = avcodec_descriptor_get(params->codec_id);
            if (desc && (desc->props & AV_CODEC_PROP_TEXT_SUB)) track.kind = "text";
            else if (desc && (desc->props & AV_CODEC_PROP_BITMAP_SUB)) track.kind = "bitmap";
            result.subtitles.push_back(std::move(track));
        }
    }
    for (unsigned i = 0; i < std::min(format->nb_chapters, 128u); ++i) {
        const auto chapter = format->chapters[i];
        result.chapters.push_back({Milliseconds(chapter->start, chapter->time_base),
            Milliseconds(chapter->end, chapter->time_base), budget.Read(chapter->metadata, "title")});
    }
    const AVDictionaryEntry *entry = nullptr;
    while (result.tags.size() < 64 && budget.remaining > 0 && (entry = av_dict_get(format->metadata, "", entry, AV_DICT_IGNORE_SUFFIX))) {
        auto key = budget.Take(entry->key, 128); auto value = budget.Take(entry->value, 512);
        if (!key.empty()) result.tags.emplace(std::move(key), std::move(value));
    }
    Check(state); return result;
}

Frame ExtractFrame(const std::string &input, RequestState &state, int timeoutMs, int64_t timeMs, int maxWidth, int maxHeight) {
    Input source(input, state, timeoutMs); auto *format = source.context;
    const AVCodec *decoder = nullptr;
    const int index = av_find_best_stream(format, AVMEDIA_TYPE_VIDEO, -1, -1, &decoder, 0);
    if (index == AVERROR_DECODER_NOT_FOUND) Fail("FF_DECODER_UNAVAILABLE", index);
    if (index < 0) Fail("FF_NO_VIDEO", index);
    auto *stream = format->streams[index];
    std::unique_ptr<AVCodecContext, decltype(&FreeCodec)> codec(avcodec_alloc_context3(decoder), FreeCodec);
    if (!codec) Fail("FF_SIZE_REJECTED");
    int status = avcodec_parameters_to_context(codec.get(), stream->codecpar);
    if (status < 0) Fail("FF_DECODER_UNAVAILABLE", status);
    codec->thread_count = 1; codec->max_pixels = 32 * 1024 * 1024;
    status = avcodec_open2(codec.get(), decoder, nullptr); if (status < 0) Fail("FF_DECODER_UNAVAILABLE", status);
    const int64_t start = stream->start_time == AV_NOPTS_VALUE ? 0 : stream->start_time;
    const int64_t offset = av_rescale_q(timeMs, AVRational{1, 1000}, stream->time_base);
    if (offset < 0 || start > INT64_MAX - offset) Fail("FF_DECODE_FAILED");
    const int64_t target = offset + start;
    if (timeMs > 0) {
        status = av_seek_frame(format, index, target, AVSEEK_FLAG_BACKWARD);
        if (status < 0) { Check(state); Fail("FF_DECODE_FAILED", status); }
        avcodec_flush_buffers(codec.get());
    }
    std::unique_ptr<AVFrame, decltype(&FreeFrame)> frame(av_frame_alloc(), FreeFrame), last(av_frame_alloc(), FreeFrame);
    std::unique_ptr<AVPacket, decltype(&FreePacket)> packet(av_packet_alloc(), FreePacket);
    if (!frame || !last || !packet) Fail("FF_SIZE_REJECTED");
    bool drained = false, selected = false;
    while (!selected) {
        Check(state); status = avcodec_receive_frame(codec.get(), frame.get());
        if (status == 0) {
            if (frame->best_effort_timestamp == AV_NOPTS_VALUE || frame->best_effort_timestamp >= target) { selected = true; break; }
            av_frame_unref(last.get()); status = av_frame_ref(last.get(), frame.get());
            if (status < 0) Fail("FF_SIZE_REJECTED", status);
            av_frame_unref(frame.get()); continue;
        }
        if (status == AVERROR_EOF) {
            if (last->data[0]) { frame.swap(last); selected = true; break; }
            Fail("FF_DECODE_FAILED", status);
        }
        if (status != AVERROR(EAGAIN) || drained) Fail("FF_DECODE_FAILED", status);
        do {
            av_packet_unref(packet.get()); Check(state); status = av_read_frame(format, packet.get());
        } while (status >= 0 && packet->stream_index != index);
        if (status < 0 && status != AVERROR_EOF) { Check(state); Fail("FF_DECODE_FAILED", status); }
        drained = status == AVERROR_EOF;
        status = avcodec_send_packet(codec.get(), drained ? nullptr : packet.get());
        av_packet_unref(packet.get()); if (status < 0) Fail("FF_DECODE_FAILED", status);
    }
    Check(state);
    const auto sar = av_guess_sample_aspect_ratio(format, stream, frame.get());
    const auto dimensions = Fit(frame->width, frame->height, maxWidth, maxHeight, sar.num > 0 && sar.den > 0 ? av_q2d(sar) : 1);
    const auto bytes = FrameBytes(dimensions.width, dimensions.height); if (!bytes) Fail("FF_SIZE_REJECTED");
    Frame result; result.width = dimensions.width; result.height = dimensions.height;
    const int64_t stamp = frame->best_effort_timestamp;
    const bool safeStamp = stamp != AV_NOPTS_VALUE && !(start < 0 && stamp > INT64_MAX + start);
    result.timeMs = safeStamp && stamp >= start ? Milliseconds(stamp - start, stream->time_base) : 0;
    result.pixels.resize(bytes);
    std::unique_ptr<SwsContext, decltype(&sws_freeContext)> scale(sws_getContext(frame->width, frame->height,
        static_cast<AVPixelFormat>(frame->format), result.width, result.height, AV_PIX_FMT_RGBA, SWS_BILINEAR, nullptr, nullptr, nullptr), sws_freeContext);
    if (!scale) Fail("FF_SIZE_REJECTED");
    uint8_t *output[] = {result.pixels.data(), nullptr, nullptr, nullptr}; int stride[] = {result.width * 4, 0, 0, 0};
    status = sws_scale(scale.get(), frame->data, frame->linesize, 0, frame->height, output, stride);
    if (status != result.height) Fail("FF_DECODE_FAILED");
    Check(state); return result;
}
}
