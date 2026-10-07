'use strict';
const { runCompatSuite } = require('./run_research_suite.cjs');

const compatCases = [
  {
    caseId: 'compat-mp4-h264',
    directoryPath: '/x',
    fileName: 'output (1).mp4',
    container: 'mp4',
    expectedDurationMs: 30000,
    expectedWidth: 1920,
    expectedHeight: 1080
  },
  {
    caseId: 'compat-mp4-longgop',
    directoryPath: '/x',
    fileName: 'output.mp4',
    container: 'mp4',
    expectedDurationMs: 120000,
    expectedWidth: 1920,
    expectedHeight: 1080
  },
  {
    caseId: 'compat-mkv-h264',
    directoryPath: '/movie/Fan 2016 Hindi 1080p BluRay x264 DD 5.1 MSubs - LOKiHD - Telly',
    fileName: 'SaMple.mkv',
    container: 'mkv',
    expectedDurationMs: 60000,
    expectedWidth: 1920,
    expectedHeight: 1080
  },
  {
    caseId: 'compat-webm-vp9',
    directoryPath: '/duanju/《我的兄弟是王承恩》最狂閹黨——更新中 [PLec-c_HqNwTHvfj3glIRZvRcDnkyqHtqD]',
    fileName: '古裝沙雕《我的兄弟是王承恩》最狂閹黨 EP84-85｜蝦仁穿越大明 因窮偷了因錢包結緣錦衣衛當了富人家乾兒子 好友为了我確結緣東廠 #穿越劇 #蝦仁 #沙雕動漫 #沙雕動畫 #小说改编.webm',
    container: 'webm',
    expectedDurationMs: 180000,
    expectedWidth: 1920,
    expectedHeight: 1080
  },
  {
    caseId: 'compat-mkv-hevc10-4k',
    directoryPath: '/movie/战士',
    fileName: 'Jawan.2023.2160p.4K.WEB.x265.10bit.AAC5.1.mkv',
    container: 'mkv',
    expectedDurationMs: 9000000,
    expectedWidth: 3840,
    expectedHeight: 2160
  },
  {
    caseId: 'compat-mkv-hevc10-1080p',
    directoryPath: '/movie/玩命记忆',
    fileName: 'Unknown.2006.BluRay.1080p.DTS-HD.MA5.1.x265.10bit-ALT.mkv',
    container: 'mkv',
    expectedDurationMs: 5100000,
    expectedWidth: 1920,
    expectedHeight: 1080
  },
  {
    caseId: 'compat-mkv-hdr10-4k',
    directoryPath: '/movie/感恩节',
    fileName: 'Thanksgiving.2023.2160p.iTunes.WEB-DL.DD.5.1.HDR10.H.265-DreamHD.mkv',
    container: 'mkv',
    expectedDurationMs: 6360000,
    expectedWidth: 3840,
    expectedHeight: 2160
  },
  {
    caseId: 'compat-mkv-dovi-4k',
    directoryPath: '/movie/The.Batman.2022.2160p.BluRay.DoVi.x265.10bit.Atmos.TrueHD7.1-WiKi',
    fileName: 'The.Batman.2022.2160p.BluRay.DoVi.x265.10bit.Atmos.TrueHD7.1-WiKi.mkv',
    container: 'mkv',
    expectedDurationMs: 10560000,
    expectedWidth: 3840,
    expectedHeight: 2160
  },
  {
    caseId: 'compat-mkv-remux-4k',
    directoryPath: '/movie/绝密型战.2024.2160p.AMZN.WEB-DL.DDP5.1.Atmos.HDR.H.265-DreamHD',
    fileName: '盟军敢死队.The.Ministry.of.Ungentlemanly.Warfare.2024.2160p.AMZN.WEB-DL.DDP5.1.Atmos.HDR.H.265-DreamHD.mkv',
    container: 'mkv',
    expectedDurationMs: 7200000,
    expectedWidth: 3840,
    expectedHeight: 2160
  },
  {
    caseId: 'compat-mkv-hevc-60fps-4k',
    directoryPath: '/movie/从21世纪安全撤离',
    fileName: '从21世纪安全撤离.Evacuate.from.the.21st.Century.2024.2160p.HQ.WEB-DL.DDP5.1.H265.60fps-ParkHD.mkv',
    container: 'mkv',
    expectedDurationMs: 5880000,
    expectedWidth: 3840,
    expectedHeight: 2160
  },
  {
    caseId: 'compat-mp4-webdl-1080p',
    directoryPath: '/aria2',
    fileName: 'S01E09.1080p.WEB-DL.H264-MBRS.mp4',
    container: 'mp4',
    expectedDurationMs: 2700000,
    expectedWidth: 1920,
    expectedHeight: 1080
  }
];

(async () => {
  try {
    const records = await runCompatSuite(compatCases, 600000);
    console.log(`Compat suite finished! Collected ${records.length} records`);
    process.exit(0);
  } catch (e) {
    console.error('Compat suite failed:', e);
    process.exit(1);
  }
})();
