#include "../../main/cpp/request_state.h"
#include <cassert>
#include <iostream>

int main()
{
    using namespace linkora_ffmpeg;
    if (BoundedMetadataText("中文", 512) != "中文") {
        std::cerr << "FAIL: bounded metadata removed an untruncated Chinese character\n";
        return 1;
    }
    assert(BoundedMetadataText("中文", 4) == "中");
    assert(BoundedMetadataText("中文", 6) == "中文");
    assert(ValidInput("/data/app/fixture.mp4"));
    assert(ValidInput("http://127.0.0.1:12345/abcdef123456"));
    for (const auto &input : {"http://example.org/a", "http://127.0.0.1:2@evil/a",
            "http://127.0.0.1:0/a", "http://127.0.0.1:65536/a", "file:///data/a",
            "content://abc", "http://127.0.0.1:2/a?secret=x", "//remote/a", "relative.mp4", "/data/a\n"}) {
        assert(!ValidInput(input));
    }
    assert(!ValidInput(std::string("/data/a\0x", 9)));
    assert(!ValidInput("/" + std::string(4096, 'a')));
    auto fit = Fit(1920, 1080, 480, 270); assert(fit.width == 480 && fit.height == 270);
    fit = Fit(1080, 1920, 480, 270); assert(fit.width == 151 && fit.height == 270);
    fit = Fit(100, 50, 480, 270); assert(fit.width == 100 && fit.height == 50);
    fit = Fit(720, 576, 480, 270, 16.0 / 15); assert(fit.width == 360 && fit.height == 270);
    assert(FrameBytes(480, 270) == 518400);
    assert(FrameBytes(0, 270) == 0 && FrameBytes(100000, 100000) == 0);
    assert(Fit(100, 100, 480, 270, 1e308).width == 0);
    const auto now = Clock::now();
    RequestState first(now + std::chrono::milliseconds(10)), second(now + std::chrono::milliseconds(10));
    first.Cancel(); assert(first.Poll(now) == RequestStatus::Cancelled);
    assert(second.Poll(now) == RequestStatus::Active);
    assert(second.Poll(now + std::chrono::milliseconds(10)) == RequestStatus::Timeout);
    second.Cancel(); assert(second.Poll(now) == RequestStatus::Timeout);
    RequestState complete(now + std::chrono::milliseconds(10)); complete.Finish(now); complete.Cancel();
    assert(complete.Poll(now + std::chrono::seconds(1)) == RequestStatus::Completed);
    std::cout << "native input/bounds/aspect/isolated cancel/deadline/terminal checks PASS\n";
}
