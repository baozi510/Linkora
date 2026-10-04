import native from 'liblinkora_ffmpeg.so';
import { FfmpegAnalysis } from './src/main/ets/FfmpegAnalysis';

// Explicit native entry point keeps pure mapper/lifetime tests independent of NAPI loading.
export function createFfmpegAnalysis(): FfmpegAnalysis { return new FfmpegAnalysis(native); }
