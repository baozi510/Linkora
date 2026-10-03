import { describe, expect, it } from '@ohos/hypium';
import { AppSettings, RemoteProtocol } from 'linkora_core';
import { NetworkAddressParser, ParsedServerAddress, ParsedWebUrl } from
  '../main/ets/models/NetworkAddressParser';

export default function networkAddressParserTest(): void {
  describe('NetworkAddressParser', () => {
    it('parsesWebDavUrlWithCredentials', 0, () => {
      const parsed: ParsedWebUrl | null = NetworkAddressParser.parseWeb(
        'https://user:pass@example.com:8443/media');
      expect(parsed?.host).assertEqual('example.com');
      expect(parsed?.port).assertEqual(8443);
      expect(parsed?.rootPath).assertEqual('/media');
      expect(parsed?.username).assertEqual('user');
      expect(parsed?.password).assertEqual('pass');
    });

    it('defaultsSchemeLessWebAddressToHttps', 0, () => {
      const parsed: ParsedWebUrl | null = NetworkAddressParser.parseWeb('nas.local/dav');
      expect(parsed?.secureTransport).assertTrue();
      expect(parsed?.explicitScheme).assertFalse();
      expect(parsed?.port).assertEqual(443);
    });

    it('parsesSmbAndNfsAddresses', 0, () => {
      const smb: ParsedServerAddress | null = NetworkAddressParser.parseServer(
        'smb://user:pass@nas.local/share', RemoteProtocol.SMB, 445);
      const nfs: ParsedServerAddress | null = NetworkAddressParser.parseServer(
        'nas.local:/volume/media', RemoteProtocol.NFS, 2049);
      expect(smb?.rootPath).assertEqual('/share');
      expect(smb?.username).assertEqual('user');
      expect(nfs?.rootPath).assertEqual('/volume/media');
    });

    it('rejectsWrongSchemesAndInvalidPorts', 0, () => {
      expect(NetworkAddressParser.parseServer(
        'ftp://nas.local/share', RemoteProtocol.SMB, 445)).assertNull();
      expect(NetworkAddressParser.webValidationError(
        'https://example.com:70000')).assertEqual('端口范围为 1–65535');
    });

    it('keepsExperimentalNetworkStorageDisabledByDefault', 0, () => {
      const defaults: AppSettings = new AppSettings();
      expect(defaults.experimentalNetworkStorage).assertFalse();
      expect(defaults.withExperimentalNetworkStorage(true).experimentalNetworkStorage).assertTrue();
    });
  });
}
