import { appTasks } from '@ohos/hvigor-ohos-plugin';
import { assembleSeqPlugin } from '@ohos/hvigor-multi-target-package-plugin';

export default {
  system: appTasks,
  plugins: [assembleSeqPlugin()]
};
