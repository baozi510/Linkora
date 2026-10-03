import { describe, expect, it } from '@ohos/hypium';
import { LinkIssue, MediaFormat, MediaProtocol, NetworkLinkParser } from 'linkora_core';

export default function networkLinkParserTest(): void {
  describe('NetworkLinkParser', () => {
    it('parsesHlsUrl', 0, () => {
      const result = NetworkLinkParser.parse('https://media.example.com/live/main.m3u8?token=abc');
      expect(result.isValid()).assertTrue();
      expect(result.value?.protocol).assertEqual(MediaProtocol.HTTPS);
      expect(result.value?.format).assertEqual(MediaFormat.HLS);
      expect(result.value?.host).assertEqual('media.example.com');
    });

    it('trimsInput', 0, () => {
      const result = NetworkLinkParser.parse('  http://192.168.1.10/movie.mp4  ');
      expect(result.isValid()).assertTrue();
      expect(result.value?.format).assertEqual(MediaFormat.MP4);
    });

    it('rejectsEmbeddedCredentials', 0, () => {
      const result = NetworkLinkParser.parse('https://user:password@example.com/video.mp4');
      expect(result.issue).assertEqual(LinkIssue.EMBEDDED_CREDENTIALS);
    });

    it('rejectsUnsupportedProtocol', 0, () => {
      const result = NetworkLinkParser.parse('ftp://example.com/video.mp4');
      expect(result.issue).assertEqual(LinkIssue.UNSUPPORTED_PROTOCOL);
    });

    it('rejectsEmptyInput', 0, () => {
      const result = NetworkLinkParser.parse('   ');
      expect(result.issue).assertEqual(LinkIssue.EMPTY);
    });

    it('rejectsMissingHost', 0, () => {
      const result = NetworkLinkParser.parse('https:///video.mp4');
      expect(result.issue).assertEqual(LinkIssue.MISSING_HOST);
    });

    it('rejectsTooLongInput', 0, () => {
      const result = NetworkLinkParser.parse(`https://example.com/${'a'.repeat(4096)}`);
      expect(result.issue).assertEqual(LinkIssue.TOO_LONG);
    });

    it('rejectsInvalidPort', 0, () => {
      const result = NetworkLinkParser.parse('https://example.com:invalid/video.mp4');
      expect(result.issue).assertEqual(LinkIssue.INVALID_URL);
    });

    it('preservesSignedUrl', 0, () => {
      const input = 'https://media.example.com/video.mp4?token=A%2FB%3D&expires=2000000000';
      const result = NetworkLinkParser.parse(input);
      expect(result.value?.url).assertEqual(input);
    });
  });
}
