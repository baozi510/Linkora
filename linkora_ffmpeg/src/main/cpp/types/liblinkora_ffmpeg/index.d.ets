// Reuse nominal ArkTS types at the real NAPI factory boundary.
import { NativeFfmpegApi } from '../../../ets/NativeModels';
declare const native: NativeFfmpegApi;
export default native;
