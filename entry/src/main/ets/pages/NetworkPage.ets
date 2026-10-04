import { common } from '@kit.AbilityKit';
import { AppSettings, FailureCode, NETWORK_PROTOCOL_CAPABILITIES,
  ProtocolCapability, ProtocolTestRequest, ProtocolTestResult, DiscoveredService, RemoteProtocol } from 'linkora_core';
import { AppIcon, AppIconName } from '../components/AppIcon';
import { AppIconButton } from '../components/AppIconButton';
import { AppActionListItem } from '../components/AppActionListItem';
import { AppSheetHeader } from '../components/AppSheetHeader';
import { AppSheetSurface } from '../components/AppSheetSurface';
import { ConnectionTestPanel } from '../components/ConnectionTestPanel';
import { AppToolbar } from '../components/AppToolbar';
import { NetworkProtocolTestRegistry } from 'entry/ets/adapters/NetworkProtocolTestRegistry';
import { FtpPassiveMode, FtpSecurityMode, NetworkAdvancedOptions, NetworkServerDraft,
  NetworkServerEntry, NetworkServerStore, SftpAuthMode, SftpHostKeyPolicy } from '../services/NetworkServerStore';
import { UpnpDiscoveryScanner } from '../services/UpnpDiscoveryScanner';
import { NetworkAddressParser, ParsedServerAddress, ParsedWebUrl } from '../models/NetworkAddressParser';
import { AppColors, AppRadius, AppSpacing, AppTypography, MediaLayout } from '../ui/AppTheme';
import { RuntimeProfile } from 'entry/RuntimeProfile';

enum NetworkAddStep {
  PROTOCOL = 'protocol',
  DETAILS = 'details'
}

enum AdvancedSelectKind {
  FTP_SECURITY = 'ftp-security',
  FTP_DATA_CONNECTION = 'ftp-data-connection',
  FTP_ENCODING = 'ftp-encoding',
  SFTP_HOST_KEY = 'sftp-host-key',
  NFS_VERSION = 'nfs-version'
}

const FTP_ENCODING_OPTIONS: string[] = [
  '自动',
  'UTF-8',
  'GB18030',
  'GBK',
  'Big5',
  'Shift_JIS',
  'EUC-KR',
  'ISO-8859-1',
  'Windows-1252'
];

const FTP_ENCODING_VALUES: string[] = [
  'auto',
  'utf8',
  'gb18030',
  'gbk',
  'big5',
  'shift_jis',
  'euc-kr',
  'iso-8859-1',
  'windows-1252'
];

@ComponentV2
export struct NetworkPage {
  @Event onOpenServer: (serverId: number) => void = () => {};
  @Event onOpenSettings: () => void = () => {};
  @Consumer('linkoraAccentColor') private accentColor: string = 'system';
  @Param settings: AppSettings = new AppSettings();

  @Local private servers: NetworkServerEntry[] = [];
  @Local private loading: boolean = true;
  @Local private loadFailure: string = '';
  @Local private addSheetVisible: boolean = false;
  @Local private addStep: NetworkAddStep = NetworkAddStep.PROTOCOL;
  @Local private selectedProtocol: RemoteProtocol = RemoteProtocol.WEBDAV;
  @Local private formName: string = '';
  @Local private formHost: string = '';
  // Keep the field empty: protocol defaults are effective values, not user-entered values.
  @Local private formPort: string = '';
  @Local private webDavHttps: boolean = true;
  @Local private formPath: string = '';
  @Local private formUsername: string = '';
  @Local private formPassword: string = '';
  @Local private smbWorkgroup: string = '';
  @Local private ftpSecurityMode: FtpSecurityMode = FtpSecurityMode.AUTO;
  @Local private ftpPassiveMode: FtpPassiveMode = FtpPassiveMode.AUTO;
  @Local private ftpEncoding: string = 'auto';
  @Local private sftpAuthMode: SftpAuthMode = SftpAuthMode.PASSWORD;
  @Local private sftpHostKeyPolicy: SftpHostKeyPolicy = SftpHostKeyPolicy.ASK;
  @Local private sftpFingerprint: string = '';
  @Local private nfsVersion: string = 'auto';
  @Local private formHostError: string = '';
  @Local private formPortError: string = '';
  @Local private formPathError: string = '';
  // Empty means the scheme is still automatic. A successful connection test
  // can resolve a scheme-less WebDAV address without changing its text.
  @Local private detectedWebScheme: string = '';
  // Keep the latest text event separately because TextInput state updates can
  // be committed after the blur callback on some emulator builds.
  private lastWebDavRawValue: string = '';
  // Path input can have the same delayed state commit as the URL field. Keep
  // its latest raw value so Save always persists what the user entered.
  private lastWebDavPathValue: string = '';
  private webDavPathEdited: boolean = false;
  @Local private testMessage: string = '';
  @Local private testing: boolean = false;
  @Local private testSucceeded: boolean = false;
  @Local private saving: boolean = false;
  @Local private focusedField: string = '';
  @Local private scanning: boolean = false;
  @Local private scanMessage: string = '';
  @Local private discoveredServices: DiscoveredService[] = [];
  @Local private serverSheetVisible: boolean = false;
  @Local private serverMenuItem: NetworkServerEntry | null = null;
  @Local private savedServerTesting: boolean = false;
  @Local private savedServerTestMessage: string = '';
  @Local private savedServerTestSucceeded: boolean = false;
  @Local private editingServerId: number = -1;
  private serverListScroller: Scroller = new Scroller();
  private serverListScrollIndex: number = 0;
  private serverStore: NetworkServerStore | null = null;
  private protocolTestRegistry: NetworkProtocolTestRegistry = new NetworkProtocolTestRegistry();
  private formTestDialogController: CustomDialogController = new CustomDialogController({
    builder: this.formTestDialogContent,
    autoCancel: true,
    customStyle: true,
    alignment: DialogAlignment.Center
  });
  private savedServerTestDialogController: CustomDialogController = new CustomDialogController({
    builder: this.savedServerTestDialogContent,
    autoCancel: true,
    customStyle: true,
    alignment: DialogAlignment.Center
  });

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.serverStore = new NetworkServerStore(context);
    this.loadServers();
  }

  private async loadServers(): Promise<void> {
    if (this.serverStore === null) {
      return;
    }
    this.loading = true;
    this.loadFailure = '';
    try {
      this.servers = (await this.serverStore.load())
        .filter((server: NetworkServerEntry) => server.protocol !== RemoteProtocol.HTTP && RuntimeProfile.supportsNetworkProtocol(server.protocol));
    } catch (_error) {
      this.loadFailure = '服务器列表加载失败';
    } finally {
      this.loading = false;
    }
  }

  private protocolLabel(protocol: RemoteProtocol): string {
    if (protocol === RemoteProtocol.SMB) {
      return 'SMB / CIFS';
    }
    return protocol === RemoteProtocol.WEBDAV ? 'WebDAV' : protocol.toUpperCase();
  }

  private protocolIcon(protocol: RemoteProtocol): AppIconName {
    if (protocol === RemoteProtocol.WEBDAV) {
      return AppIconName.CLOUD;
    }
    if (protocol === RemoteProtocol.SMB) {
      return AppIconName.DNS;
    }
    if (protocol === RemoteProtocol.SFTP) {
      return AppIconName.LOCK;
    }
    if (protocol === RemoteProtocol.FTP) {
      return AppIconName.LINK;
    }
    return AppIconName.HARD_DRIVE;
  }

  private selectedCapability(): ProtocolCapability {
    for (let index: number = 0; index < NETWORK_PROTOCOL_CAPABILITIES.length; index++) {
      const capability: ProtocolCapability = NETWORK_PROTOCOL_CAPABILITIES[index];
      if (capability.protocol === this.selectedProtocol) {
        return capability;
      }
    }
    return NETWORK_PROTOCOL_CAPABILITIES[0];
  }

  private effectiveDefaultPort(): number {
    if (this.selectedProtocol === RemoteProtocol.FTP &&
      this.ftpSecurityMode === FtpSecurityMode.IMPLICIT_TLS) {
      return 990;
    }
    return this.selectedCapability().defaultPort;
  }

  private effectiveSecureTransport(): boolean {
    if (this.selectedProtocol === RemoteProtocol.WEBDAV) {
      return this.webDavHttps;
    }
    if (this.selectedProtocol === RemoteProtocol.FTP) {
      return this.ftpSecurityMode === FtpSecurityMode.EXPLICIT_TLS ||
        this.ftpSecurityMode === FtpSecurityMode.IMPLICIT_TLS;
    }
    return this.selectedCapability().secureByDefault;
  }

  private formTitle(): string {
    const action: string = this.editingServerId > 0 ? '编辑' : '添加';
    return `${action} ${this.protocolLabel(this.selectedProtocol)} 服务器`;
  }

  private serverAddressPlaceholder(): string {
    return '192.168.1.10';
  }

  private pathLabel(): string {
    if (this.selectedProtocol === RemoteProtocol.WEBDAV) {
      return '路径';
    }
    if (this.selectedProtocol === RemoteProtocol.SMB) {
      return '共享目录';
    }
    if (this.selectedProtocol === RemoteProtocol.NFS) {
      return '导出目录';
    }
    return '远程目录';
  }

  private pathPlaceholder(): string {
    if (this.selectedProtocol === RemoteProtocol.WEBDAV) {
      return 'media';
    }
    if (this.selectedProtocol === RemoteProtocol.SMB) {
      return '留空自动发现共享';
    }
    if (this.selectedProtocol === RemoteProtocol.NFS) {
      return 'volume/media';
    }
    return 'media';
  }

  private portPlaceholder(): string {
    if (this.selectedProtocol === RemoteProtocol.WEBDAV) {
      const parsedUrl: ParsedWebUrl | null = this.parseWebUrl(this.formHost);
      if (parsedUrl !== null) {
        return this.webDavHttps ? '443' : '80';
      }
    }
    return this.effectiveDefaultPort().toString();
  }

  private parseServerAddress(rawValue: string): ParsedServerAddress | null {
    return NetworkAddressParser.parseServer(rawValue, this.selectedProtocol, this.effectiveDefaultPort());
  }

  private serverAddressValidationError(rawValue: string): string {
    return NetworkAddressParser.serverValidationError(
      rawValue, this.selectedProtocol, this.effectiveDefaultPort());
  }

  private syncServerAddressFields(): void {
    const parsed: ParsedServerAddress | null = this.parseServerAddress(this.formHost);
    if (parsed === null) {
      return;
    }
    this.formHost = parsed.host;
    this.formPort = parsed.explicitPort ? parsed.port.toString() : this.formPort;
    if (parsed.rootPath !== '/') {
      this.formPath = parsed.rootPath;
    }
    if (parsed.username.length > 0) {
      this.formUsername = parsed.username;
      this.formPassword = parsed.password;
    }
    if (this.selectedProtocol === RemoteProtocol.FTP && parsed.scheme === 'ftps') {
      this.ftpSecurityMode = FtpSecurityMode.EXPLICIT_TLS;
    }
  }

  private openProtocolSheet(): void {
    this.editingServerId = -1;
    this.scanMessage = '';
    this.discoveredServices = [];
    this.addStep = NetworkAddStep.PROTOCOL;
    this.addSheetVisible = true;
  }

  private async scanNetwork(includeAll: boolean): Promise<void> {
    if (this.scanning) {
      return;
    }
    this.scanning = true;
    this.scanMessage = includeAll ? '正在自动扫描所有可用网络发现方式…' : '正在扫描 UPnP / DLNA 设备…';
    this.discoveredServices = [];
    try {
      this.discoveredServices = await UpnpDiscoveryScanner.scan();
      const count: number = this.discoveredServices.length;
      this.scanMessage = includeAll ?
        `扫描完成，发现 ${count} 个 UPnP / DLNA 设备。其他协议将在对应发现插件接入后自动加入。` :
        `扫描完成，发现 ${count} 个 UPnP / DLNA 设备。`;
    } catch (_error) {
      this.scanMessage = '网络扫描失败，请稍后重试';
    } finally {
      this.scanning = false;
      this.addStep = NetworkAddStep.PROTOCOL;
      this.addSheetVisible = true;
    }
  }

  private selectProtocol(capability: ProtocolCapability): void {
    this.selectedProtocol = capability.protocol;
    this.formName = '';
    this.formHost = '';
    this.lastWebDavRawValue = '';
    this.lastWebDavPathValue = '';
    this.webDavPathEdited = false;
    this.formPort = '';
    this.webDavHttps = capability.secureByDefault;
    this.formPath = '';
    this.formUsername = '';
    this.formPassword = '';
    this.resetAdvancedOptions();
    this.formHostError = '';
    this.formPortError = '';
    this.formPathError = '';
    this.detectedWebScheme = '';
    this.testMessage = '';
    this.testing = false;
    this.testSucceeded = false;
    this.addSheetVisible = false;
    setTimeout(() => {
      this.addStep = NetworkAddStep.DETAILS;
      this.addSheetVisible = true;
    }, 180);
  }

  private resetAdvancedOptions(): void {
    this.smbWorkgroup = '';
    this.ftpSecurityMode = FtpSecurityMode.AUTO;
    this.ftpPassiveMode = FtpPassiveMode.AUTO;
    this.ftpEncoding = 'auto';
    this.sftpAuthMode = SftpAuthMode.PASSWORD;
    this.sftpHostKeyPolicy = SftpHostKeyPolicy.ASK;
    this.sftpFingerprint = '';
    this.nfsVersion = 'auto';
  }

  private advancedOptions(): NetworkAdvancedOptions {
    const options: NetworkAdvancedOptions = new NetworkAdvancedOptions();
    options.workgroup = this.smbWorkgroup.trim();
    options.ftpSecurityMode = this.ftpSecurityMode;
    options.ftpPassiveMode = this.ftpPassiveMode;
    options.ftpEncoding = this.ftpEncoding;
    options.sftpAuthMode = this.sftpAuthMode;
    options.sftpHostKeyPolicy = this.sftpHostKeyPolicy;
    options.sftpFingerprint = this.sftpFingerprint.trim();
    // WebDAV uses safe automatic behavior. Exceptional redirects and TLS failures
    // are explained contextually by the connection test instead of permanent switches.
    options.webdavFollowRedirects = true;
    options.webdavVerifyTls = true;
    options.nfsVersion = this.nfsVersion;
    return options;
  }

  private normalizedPath(): string {
    const rawValue: string = this.selectedProtocol === RemoteProtocol.WEBDAV &&
      this.webDavPathEdited ? this.lastWebDavPathValue : this.formPath;
    const value: string = rawValue.trim();
    if (value.length === 0) {
      return '/';
    }
    return value.startsWith('/') ? value : `/${value}`;
  }

  private webDavPathForDisplay(path: string): string {
    const normalized: string = path.trim();
    if (normalized === '/') {
      return '';
    }
    return normalized.replace(/^\/+/, '');
  }

  private parseWebUrl(rawValue: string): ParsedWebUrl | null {
    return NetworkAddressParser.parseWeb(rawValue);
  }

  private resolvedWebSecureTransport(parsedUrl: ParsedWebUrl): boolean {
    return parsedUrl.explicitScheme ? parsedUrl.secureTransport : this.webDavHttps;
  }

  private resolvedWebPort(parsedUrl: ParsedWebUrl, secureTransport: boolean): number {
    const portText: string = this.formPort.trim();
    if (portText.length > 0) {
      return Number(portText);
    }
    if (parsedUrl.explicitPort) {
      return parsedUrl.port;
    }
    return secureTransport ? 443 : 80;
  }

  private shouldTryHttpFallback(parsedUrl: ParsedWebUrl, secureTransport: boolean,
    result: ProtocolTestResult): boolean {
    if (this.selectedProtocol !== RemoteProtocol.WEBDAV || parsedUrl.explicitScheme || !secureTransport) {
      return false;
    }
    return result.diagnosticCode.startsWith('LNK-NET-004') ||
      result.diagnosticCode.startsWith('LNK-NET-006') ||
      result.diagnosticCode.startsWith('LNK-NET-011');
  }

  private webUrlValidationError(rawValue: string): string {
    return NetworkAddressParser.webValidationError(rawValue);
  }

  private syncWebDavUrlFields(value: string, sanitizeHost: boolean = false): void {
    if (this.selectedProtocol !== RemoteProtocol.WEBDAV) {
      return;
    }
    const parsedUrl: ParsedWebUrl | null = this.parseWebUrl(value);
    if (parsedUrl === null) {
      return;
    }
    const previousSecureTransport: boolean = this.webDavHttps;
    const previousDefaultPort: number = previousSecureTransport ? 443 : 80;
    const currentPortText: string = this.formPort.trim();
    const urlDefaultPort: number = parsedUrl.explicitScheme ?
      (parsedUrl.secureTransport ? 443 : 80) : previousDefaultPort;
    const canAutofillPort: boolean = currentPortText.length === 0 ||
      Number(currentPortText) === previousDefaultPort || Number(currentPortText) === urlDefaultPort;
    if (parsedUrl.explicitScheme) {
      this.webDavHttps = parsedUrl.secureTransport;
    }
    if (parsedUrl.explicitPort && canAutofillPort) {
      this.formPort = parsedUrl.port.toString();
    }
    const schemeEnd: number = value.indexOf('://');
    const authorityStart: number = schemeEnd >= 0 ? schemeEnd + 3 : 0;
    if (value.indexOf('/', authorityStart) >= 0) {
      this.formPath = this.webDavPathForDisplay(parsedUrl.rootPath);
      this.lastWebDavPathValue = this.formPath;
      this.webDavPathEdited = false;
    }
    if (parsedUrl.username.length > 0) {
      this.formUsername = parsedUrl.username;
      this.formPassword = parsedUrl.password;
    }
    if (sanitizeHost && (parsedUrl.explicitScheme || parsedUrl.explicitPort)) {
      this.formHost = parsedUrl.host;
    }
  }

  private clearFormValidation(): void {
    this.formHostError = '';
    this.formPortError = '';
    this.formPathError = '';
  }

  private showInputError(field: string, message: string): void {
    if (field === 'host') {
      this.formHostError = message;
    } else if (field === 'port') {
      this.formPortError = message;
    } else if (field === 'path') {
      this.formPathError = message;
    }
    try {
      this.getUIContext().getPromptAction().showToast({ message });
    } catch (_error) {
    }
    this.focusFormField(field);
  }

  private showOperationError(title: string, message: string): void {
    this.getUIContext().showAlertDialog({
      title,
      message,
      cornerRadius: AppRadius.SHEET,
      primaryButton: { value: '知道了', action: () => {} }
    });
  }

  private resultHasFailureCode(result: ProtocolTestResult, code: FailureCode): boolean {
    return result.diagnosticCode === code || result.diagnosticCode.startsWith(`${code}/`);
  }

  private isWebDavDecisionFailure(result: ProtocolTestResult): boolean {
    return this.resultHasFailureCode(result, FailureCode.NETWORK_TLS_FAILED) ||
      this.resultHasFailureCode(result, FailureCode.NETWORK_REDIRECT_FAILED);
  }

  private showWebDavDecision(result: ProtocolTestResult, server: NetworkServerEntry | null = null): void {
    const tlsFailure: boolean = this.resultHasFailureCode(result, FailureCode.NETWORK_TLS_FAILED);
    const message: string = tlsFailure ?
      `服务器证书无效、不受信任或与当前域名不匹配。为保护账号密码，本次连接已停止。请检查 HTTPS 地址；使用自签名证书时，需要为该服务器配置可信证书。\n\n诊断信息：${result.diagnosticCode}` :
      `服务器在多个地址间反复跳转。正常跳转会自动跟随；出现此提示通常是 WebDAV URL、HTTP/HTTPS 或反向代理配置不一致。\n\n诊断信息：${result.diagnosticCode}`;
    this.getUIContext().showAlertDialog({
      title: tlsFailure ? '证书无法验证' : '重定向异常',
      message,
      cornerRadius: AppRadius.SHEET,
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '检查配置',
        action: () => {
          if (server !== null) {
            this.applyServerForEdit(server);
          } else {
            setTimeout(() => {
              this.focusFormField('host');
            }, 120);
          }
        }
      }
    });
  }

  private presentFormWebDavDecision(result: ProtocolTestResult): void {
    this.formTestDialogController.close();
    setTimeout(() => {
      this.showWebDavDecision(result);
    }, 180);
  }

  private presentSavedWebDavDecision(result: ProtocolTestResult, server: NetworkServerEntry): void {
    this.savedServerTestDialogController.close();
    setTimeout(() => {
      this.showWebDavDecision(result, server);
    }, 180);
  }

  private async testConnection(showDialog: boolean = true): Promise<void> {
    if (this.testing) {
      return;
    }
    this.clearFormValidation();
    this.testMessage = '';
    let host: string = this.formHost.trim();
    let port: number = 0;
    let secureTransport: boolean = this.effectiveSecureTransport();
    let parsedUrl: ParsedWebUrl | null = null;
    if (this.selectedProtocol === RemoteProtocol.WEBDAV) {
      const rawHostValue: string = this.selectedProtocol === RemoteProtocol.WEBDAV &&
        this.lastWebDavRawValue.length > 0 ? this.lastWebDavRawValue : this.formHost;
      const urlError: string = this.webUrlValidationError(rawHostValue);
      if (urlError.length > 0) {
        this.showInputError('host', urlError);
        return;
      }
      parsedUrl = this.parseWebUrl(rawHostValue);
      if (parsedUrl === null) {
        this.showInputError('host', '地址格式不正确，请检查协议、主机和端口');
        return;
      }
      secureTransport = this.resolvedWebSecureTransport(parsedUrl);
      port = this.resolvedWebPort(parsedUrl, secureTransport);
    } else {
      this.syncServerAddressFields();
      host = this.formHost.trim();
      const addressError: string = this.serverAddressValidationError(host);
      if (addressError.length > 0) {
        this.showInputError('host', addressError);
        return;
      }
      port = this.effectiveDefaultPort();
    }
    if (this.formPort.trim().length > 0) {
      port = Number(this.formPort.trim());
      if (!Number.isInteger(port) || port < 1 || port > 65535) {
        this.showInputError('port', '端口范围为 1–65535');
        return;
      }
    }
    this.testSucceeded = false;
    this.testing = true;
    this.testMessage = '正在测试连接…';
    if (showDialog) {
      this.formTestDialogController.open();
    }
    try {
      // A URL may carry WebDAV credentials (https://user:pass@host/path).
      // Use them directly here as well as in the blur synchronisation below;
      // TextInput state can still be one event behind when Test is pressed
      // immediately after editing the URL.
      let requestUsername: string = this.formUsername.trim();
      let requestPassword: string = this.formPassword;
      if (this.selectedProtocol === RemoteProtocol.WEBDAV && parsedUrl !== null &&
        parsedUrl.username.length > 0) {
        requestUsername = parsedUrl.username;
        requestPassword = parsedUrl.password;
      }
      const request: ProtocolTestRequest = new ProtocolTestRequest(
        this.selectedProtocol,
        parsedUrl === null ? host : parsedUrl.host,
        port,
        parsedUrl === null || this.selectedProtocol === RemoteProtocol.WEBDAV ?
          this.normalizedPath() : parsedUrl.rootPath,
        requestUsername,
        requestPassword,
        parsedUrl === null ? this.effectiveSecureTransport() : secureTransport,
        this.selectedProtocol === RemoteProtocol.SMB ? this.smbWorkgroup.trim() : '',
        this.sftpFingerprint.trim(), this.sftpHostKeyPolicy === SftpHostKeyPolicy.STRICT);
      let result: ProtocolTestResult = await this.protocolTestRegistry.test(request);
      let automaticallySelectedHttp: boolean = false;
      if (parsedUrl !== null && this.shouldTryHttpFallback(parsedUrl, secureTransport, result)) {
        const fallbackPort: number = parsedUrl.explicitPort || this.formPort.trim().length > 0 ? port : 80;
        const fallbackRequest: ProtocolTestRequest = new ProtocolTestRequest(
          this.selectedProtocol,
          parsedUrl.host,
          fallbackPort,
          this.selectedProtocol === RemoteProtocol.WEBDAV ? this.normalizedPath() : parsedUrl.rootPath,
          requestUsername,
          requestPassword,
          false,
          this.selectedProtocol === RemoteProtocol.SMB ? this.smbWorkgroup.trim() : '',
        this.sftpFingerprint.trim(), this.sftpHostKeyPolicy === SftpHostKeyPolicy.STRICT);
        const fallbackResult: ProtocolTestResult = await this.protocolTestRegistry.test(fallbackRequest);
        if (fallbackResult.succeeded) {
          result = fallbackResult;
          this.detectedWebScheme = 'http';
          automaticallySelectedHttp = true;
        }
      } else if (parsedUrl !== null && !parsedUrl.explicitScheme && result.succeeded) {
        this.detectedWebScheme = secureTransport ? 'https' : 'http';
      }
      this.testSucceeded = result.succeeded;
      this.testMessage = `${result.title}：${result.message}${automaticallySelectedHttp ? '（已自动使用 HTTP）' : ''}`;
      if (!result.succeeded && this.selectedProtocol === RemoteProtocol.WEBDAV &&
        this.isWebDavDecisionFailure(result)) {
        this.presentFormWebDavDecision(result);
      }
    } catch (_error) {
      this.testSucceeded = false;
      this.testMessage = '连接测试失败，请检查地址和网络';
    } finally {
      this.testing = false;
    }
  }

  private inputBorderColor(field: string): ResourceColor {
    if (field === 'host' && this.formHostError.length > 0) {
      return AppColors.ERROR_TEXT;
    }
    if (field === 'port' && this.formPortError.length > 0) {
      return AppColors.ERROR_TEXT;
    }
    if (field === 'path' && this.formPathError.length > 0) {
      return AppColors.ERROR_TEXT;
    }
    return this.focusedField === field ? AppColors.accent(this.accentColor) : AppColors.OUTLINE;
  }

  private focusFormField(field: string): void {
    let focusKey: string = '';
    switch (field) {
      case 'name':
        focusKey = 'network-form-name';
        break;
      case 'host':
        focusKey = 'network-form-host';
        break;
      case 'port':
        focusKey = 'network-form-port';
        break;
      case 'path':
        focusKey = 'network-form-path';
        break;
      case 'username':
        focusKey = 'network-form-username';
        break;
      case 'password':
        focusKey = 'network-form-password';
        break;
      default:
        break;
    }
    if (focusKey.length > 0) {
      setTimeout(() => {
        focusControl.requestFocus(focusKey);
      }, 0);
    }
  }

  private async saveServer(): Promise<void> {
    if (this.serverStore === null || this.saving) {
      return;
    }
    this.clearFormValidation();
    let host: string = this.formHost.trim();
    let port: number = 0;
    let rootPath: string = '/';
    let secureTransport: boolean = false;
    let serverUsername: string = this.formUsername.trim();
    let serverPassword: string = this.formPassword;
    if (this.selectedProtocol === RemoteProtocol.WEBDAV) {
      const rawHostValue: string = this.selectedProtocol === RemoteProtocol.WEBDAV &&
        this.lastWebDavRawValue.length > 0 ? this.lastWebDavRawValue : this.formHost;
      const parsedUrl: ParsedWebUrl | null = this.parseWebUrl(rawHostValue);
      const urlError: string = this.webUrlValidationError(rawHostValue);
      if (urlError.length > 0) {
        this.showInputError('host', urlError);
        return;
      }
      if (parsedUrl === null) {
        this.showInputError('host', '地址格式不正确，请检查协议、主机和端口');
        return;
      }
      host = parsedUrl.host;
      if (this.selectedProtocol === RemoteProtocol.WEBDAV && parsedUrl.username.length > 0) {
        serverUsername = parsedUrl.username;
        serverPassword = parsedUrl.password;
      }
      secureTransport = this.resolvedWebSecureTransport(parsedUrl);
      port = this.resolvedWebPort(parsedUrl, secureTransport);
      if (!Number.isInteger(port) || port < 1 || port > 65535) {
        this.showInputError('port', '端口范围为 1–65535');
        return;
      }
      rootPath = this.normalizedPath();
    } else {
      this.syncServerAddressFields();
      host = this.formHost.trim();
      const addressError: string = this.serverAddressValidationError(host);
      if (addressError.length > 0) {
        this.showInputError('host', addressError);
        return;
      }
      port = this.formPort.trim().length > 0 ? Number(this.formPort.trim()) : this.effectiveDefaultPort();
      if (!Number.isInteger(port) || port < 1 || port > 65535) {
        this.showInputError('port', '端口范围为 1–65535');
        return;
      }
      rootPath = this.normalizedPath();
      secureTransport = this.effectiveSecureTransport();
    }

    const displayName: string = this.formName.trim();
    this.saving = true;
    try {
      const draft: NetworkServerDraft = new NetworkServerDraft(
        displayName,
        this.selectedProtocol,
        host,
        port,
        rootPath,
        serverUsername,
        serverPassword,
        secureTransport,
        this.advancedOptions());
      const entries: NetworkServerEntry[] = this.editingServerId > 0 ?
        await this.serverStore.update(this.editingServerId, draft) : await this.serverStore.add(draft);
      this.servers = entries.filter((server: NetworkServerEntry) => server.protocol !== RemoteProtocol.HTTP && RuntimeProfile.supportsNetworkProtocol(server.protocol));
      this.addSheetVisible = false;
      this.editingServerId = -1;
    } catch (_error) {
      this.showOperationError('保存失败', '服务器配置未保存，请稍后重试。');
    } finally {
      this.saving = false;
    }
  }

  @Builder
  private toolbarActions() {
    AppIconButton({
      icon: AppIconName.ADD,
      label: '添加服务器',
      onPressed: () => {
        this.openProtocolSheet();
      }
    })
  }

  private closeServerMenu(): void {
    this.serverSheetVisible = false;
    this.serverMenuItem = null;
  }

  private openServerMenu(server: NetworkServerEntry): void {
    this.serverMenuItem = server;
    this.serverSheetVisible = true;
  }

  private testSavedServer(server: NetworkServerEntry): void {
    this.serverMenuItem = server;
    this.serverSheetVisible = false;
    this.savedServerTesting = false;
    this.savedServerTestMessage = '准备测试连接…';
    this.savedServerTestSucceeded = false;
    setTimeout(() => {
      this.savedServerTestDialogController.open();
      this.runSavedServerTest(server);
    }, 180);
  }

  private async runSavedServerTest(server: NetworkServerEntry): Promise<void> {
    this.savedServerTesting = true;
    this.savedServerTestMessage = '正在测试连接…';
    try {
      const request: ProtocolTestRequest = new ProtocolTestRequest(
        server.protocol, server.host, server.port, server.rootPath, server.username,
        server.password, server.secureTransport, server.advancedOptions.workgroup,
        server.advancedOptions.sftpFingerprint, server.advancedOptions.sftpHostKeyPolicy === SftpHostKeyPolicy.STRICT);
      const result: ProtocolTestResult = await this.protocolTestRegistry.test(request);
      this.savedServerTestSucceeded = result.succeeded;
      this.savedServerTestMessage = `${result.title}：${result.message}`;
      if (!result.succeeded && server.protocol === RemoteProtocol.WEBDAV &&
        this.isWebDavDecisionFailure(result)) {
        this.presentSavedWebDavDecision(result, server);
      }
    } catch (_error) {
      this.savedServerTestSucceeded = false;
      this.savedServerTestMessage = '连接测试失败，请检查地址和网络';
    } finally {
      this.savedServerTesting = false;
    }
  }

  private applyServerForEdit(server: NetworkServerEntry): void {
    this.editingServerId = server.id;
    this.selectedProtocol = server.protocol;
    this.formName = server.displayName === server.host ? '' : server.displayName;
    this.formPath = server.rootPath === '/' ? '' :
      (server.protocol === RemoteProtocol.WEBDAV ? this.webDavPathForDisplay(server.rootPath) : server.rootPath);
    this.formUsername = server.username;
    this.formPassword = server.password;
    this.detectedWebScheme = '';
    this.lastWebDavRawValue = '';
    this.lastWebDavPathValue = server.protocol === RemoteProtocol.WEBDAV ? this.formPath : '';
    this.webDavPathEdited = false;
    if (server.protocol === RemoteProtocol.WEBDAV) {
      const defaultPort: number = server.secureTransport ? 443 : 80;
      this.webDavHttps = server.secureTransport;
      this.formHost = server.host;
      this.formPort = server.port === defaultPort ? '' : server.port.toString();
    } else {
      this.formHost = server.host;
    }
    this.smbWorkgroup = server.advancedOptions.workgroup;
    this.ftpSecurityMode = server.advancedOptions.ftpSecurityMode;
    this.ftpPassiveMode = server.advancedOptions.ftpPassiveMode;
    this.ftpEncoding = server.advancedOptions.ftpEncoding;
    this.sftpAuthMode = server.advancedOptions.sftpAuthMode;
    this.sftpHostKeyPolicy = server.advancedOptions.sftpHostKeyPolicy;
    this.sftpFingerprint = server.advancedOptions.sftpFingerprint;
    this.nfsVersion = server.advancedOptions.nfsVersion;
    let defaultPort: number = this.protocolDefaultPort(server.protocol);
    if (server.protocol === RemoteProtocol.WEBDAV) {
      defaultPort = server.secureTransport ? 443 : 80;
    } else if (server.protocol === RemoteProtocol.FTP &&
      server.advancedOptions.ftpSecurityMode === FtpSecurityMode.IMPLICIT_TLS) {
      defaultPort = 990;
    }
    if (server.protocol !== RemoteProtocol.WEBDAV) {
      this.formPort = server.port === defaultPort ? '' : server.port.toString();
    }
    this.clearFormValidation();
    this.testMessage = '';
    this.addStep = NetworkAddStep.DETAILS;
    this.closeServerMenu();
    setTimeout(() => {
      this.addSheetVisible = true;
    }, 180);
  }

  private protocolDefaultPort(protocol: RemoteProtocol): number {
    for (let index: number = 0; index < NETWORK_PROTOCOL_CAPABILITIES.length; index++) {
      const capability: ProtocolCapability = NETWORK_PROTOCOL_CAPABILITIES[index];
      if (capability.protocol === protocol) {
        return capability.defaultPort;
      }
    }
    return 0;
  }

  private openServer(server: NetworkServerEntry): void {
    this.closeServerMenu();
    if (server.protocol !== RemoteProtocol.HTTP) {
      this.onOpenServer(server.id);
    }
  }

  private confirmDeleteServer(server: NetworkServerEntry): void {
    this.closeServerMenu();
    this.getUIContext().showAlertDialog({
      title: '删除服务器',
      message: `确定要删除“${server.titleLabel()}”吗？`,
      cornerRadius: AppRadius.SHEET,
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '删除',
        action: () => {
          this.removeServer(server.id);
        }
      }
    });
  }

  private async removeServer(id: number): Promise<void> {
    if (this.serverStore === null) {
      return;
    }
    try {
      this.servers = (await this.serverStore.remove(id))
        .filter((server: NetworkServerEntry) => server.protocol !== RemoteProtocol.HTTP && RuntimeProfile.supportsNetworkProtocol(server.protocol));
    } catch (_error) {
      this.showOperationError('删除失败', '服务器仍保留在列表中，请稍后重试。');
    }
  }

  @Builder
  private serverMenuAction(icon: AppIconName, label: string, action: () => void,
    destructive: boolean = false) {
    Button() {
      Row({ space: 12 }) {
        AppIcon({ name: icon, iconSize: 20,
          color: destructive ? AppColors.DESTRUCTIVE_ACTION : AppColors.ICON_PRIMARY })
        Text(label)
          .fontSize(AppTypography.BODY)
          .fontColor(destructive ? AppColors.DESTRUCTIVE_ACTION : AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
          .textAlign(TextAlign.Start)
      }
      .width('100%')
      .height('100%')
    }
    .type(ButtonType.Normal)
    .width('100%')
    .height(40)
    .padding({ left: 14, right: 14 })
    .backgroundColor(Color.Transparent)
    .borderRadius(AppRadius.SMALL)
    .onClick(() => {
      action();
    })
  }

  @Builder
  private serverMenuContent() {
    Column({ space: 2 }) {
      if (this.serverMenuItem !== null) {
        AppSheetHeader({ title: this.serverMenuItem.titleLabel() })
        .padding({ left: 14, right: 14, top: 12, bottom: 12 })
        Divider()
          .color(AppColors.DIVIDER)
          .margin({ left: 14, right: 14 })
        this.serverMenuAction(AppIconName.PLAY_ARROW, '打开', () => {
          if (this.serverMenuItem !== null) {
            this.openServer(this.serverMenuItem);
          }
        })
        this.serverMenuAction(AppIconName.CHECK_CIRCLE, '测试连接', () => {
          if (this.serverMenuItem !== null) {
            this.testSavedServer(this.serverMenuItem);
          }
        })
        this.serverMenuAction(AppIconName.EDIT, '编辑', () => {
          if (this.serverMenuItem !== null) {
            this.applyServerForEdit(this.serverMenuItem);
          }
        })
        this.serverMenuAction(AppIconName.DELETE, '删除', () => {
          if (this.serverMenuItem !== null) {
            this.confirmDeleteServer(this.serverMenuItem);
          }
        }, true)
      }
    }
    .width('100%')
    .padding({ top: 4, bottom: 8 })
  }

  @Builder
  private formTestDialogContent() {
    ConnectionTestPanel({
      title: '测试连接',
      target: this.formName.trim().length > 0 ? this.formName.trim() : this.formHost.trim(),
      testing: this.testing,
      succeeded: this.testSucceeded,
      message: this.testMessage,
      canRetry: true,
      onRetry: () => {
        this.testConnection(false);
      },
      onClose: () => {
        this.formTestDialogController.close();
      }
    })
  }

  @Builder
  private savedServerTestDialogContent() {
    ConnectionTestPanel({
      title: '测试连接',
      target: this.serverMenuItem === null ? '' : this.serverMenuItem.titleLabel(),
      testing: this.savedServerTesting,
      succeeded: this.savedServerTestSucceeded,
      message: this.savedServerTestMessage,
      canRetry: true,
      onRetry: () => {
        if (this.serverMenuItem !== null) {
          this.runSavedServerTest(this.serverMenuItem);
        }
      },
      onClose: () => {
        this.savedServerTestDialogController.close();
        this.serverMenuItem = null;
      }
    })
  }

  @Builder
  private serverSheetContent() {
    AppSheetSurface() {
      this.serverMenuContent()
    }
  }

  @Builder
  private emptyState() {
    Column({ space: 10 }) {
      AppIcon({ name: AppIconName.DNS, iconSize: 42, color: AppColors.ICON_TERTIARY })
      Text('还没有服务器')
        .fontSize(AppTypography.SECTION_TITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
      Text('添加网络服务器后，可以浏览其中的媒体文件')
        .fontSize(AppTypography.CAPTION)
        .fontColor(AppColors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
      Button('添加服务器')
        .type(ButtonType.Normal)
        .height(38)
        .margin({ top: 6 })
        .padding({ left: 18, right: 18 })
        .fontSize(AppTypography.BODY)
        .fontColor(AppColors.accentForeground(this.accentColor))
        .backgroundColor(AppColors.accent(this.accentColor))
        .borderRadius(AppRadius.CONTROL)
        .onClick(() => {
          this.openProtocolSheet();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ left: 32, right: 32, bottom: 52 })
  }

  @Builder
  private serverRow(server: NetworkServerEntry) {
    AppActionListItem({
      itemHeight: MediaLayout.NETWORK_SERVER_ITEM_HEIGHT,
      selected: this.serverSheetVisible && this.serverMenuItem?.id === server.id,
      showTrailingAction: false,
      accessibilityLabel: `打开 ${server.titleLabel()}`,
      menuAccessibilityLabel: '服务器菜单',
      onOpen: () => {
        this.openServer(server);
      },
      onOpenMenu: () => {
        this.openServerMenu(server);
      }
    }) {
      Row({ space: 8 }) {
        Row() {
          AppIcon({ name: this.protocolIcon(server.protocol), iconSize: 28,
            color: AppColors.accent(this.accentColor) })
        }
        .width(48)
        .height(48)
        .justifyContent(FlexAlign.Center)

        Column({ space: 3 }) {
          Row({ space: 6 }) {
            Text(server.titleLabel())
              .fontSize(AppTypography.BODY)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT_PRIMARY)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            if (server.secureTransport) {
              AppIcon({ name: AppIconName.LOCK, iconSize: 12, color: AppColors.ICON_TERTIARY })
            }
          }
          .width('100%')
          Text(this.protocolLabel(server.protocol))
            .fontSize(AppTypography.CAPTION)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.accent(this.accentColor))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
    }
  }

  private serverListKey(server: NetworkServerEntry): string {
    // The id stays stable when a server is edited. Include updatedAt so
    // ArkUI's ForEach rebuilds the row immediately after a save instead of
    // retaining the old name/path until the page is recreated.
    return `${server.id}:${server.updatedAt}`;
  }

  @Builder
  private protocolOption(capability: ProtocolCapability) {
    Button() {
      Row({ space: 12 }) {
        AppIcon({ name: this.protocolIcon(capability.protocol), iconSize: 22,
          color: AppColors.accent(this.accentColor) })
          .width(30)
        Column({ space: 3 }) {
          Text(this.protocolLabel(capability.protocol))
            .fontSize(AppTypography.BODY)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        AppIcon({ name: AppIconName.CHEVRON_RIGHT, iconSize: 16, color: AppColors.ICON_TERTIARY })
      }
      .width('100%')
    }
    .type(ButtonType.Normal)
    .width('100%')
    .height(50)
    .padding({ left: 0, right: 0 })
    .backgroundColor(Color.Transparent)
    .onClick(() => {
      this.selectProtocol(capability);
    })
  }

  @Builder
  private scanOption(label: string, icon: AppIconName, onClick: () => void) {
    Button() {
      Row({ space: 12 }) {
        AppIcon({ name: icon, iconSize: 22, color: AppColors.accent(this.accentColor) })
          .width(30)
        Text(label)
          .fontSize(AppTypography.BODY)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
        AppIcon({ name: AppIconName.CHEVRON_RIGHT, iconSize: 16, color: AppColors.ICON_TERTIARY })
      }
      .width('100%')
    }
    .type(ButtonType.Normal)
    .width('100%')
    .height(50)
    .padding({ left: 0, right: 0 })
    .backgroundColor(Color.Transparent)
    .onClick(() => {
      onClick();
    })
  }

  @Builder
  private discoveredServiceRow(service: DiscoveredService) {
    Row({ space: 10 }) {
      AppIcon({ name: AppIconName.LAN, iconSize: 20, color: AppColors.accent(this.accentColor) })
      Column({ space: 2 }) {
        Text(service.displayName)
          .fontSize(AppTypography.BODY)
          .fontColor(AppColors.TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`${service.host}:${service.port}`)
          .fontSize(AppTypography.CAPTION)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .height(48)
  }

  @Builder
  private protocolSheet() {
    Column() {
      AppSheetHeader({ title: '选择网络类型' })
        .padding({ bottom: 12 })
      ForEach(NETWORK_PROTOCOL_CAPABILITIES.filter((capability: ProtocolCapability) =>
        capability.protocol !== RemoteProtocol.HTTP &&
        RuntimeProfile.supportsNetworkProtocol(capability.protocol)), (capability: ProtocolCapability) => {
        this.protocolOption(capability)
      }, (capability: ProtocolCapability) => capability.protocol)
      Row()
        .width('100%')
        .height(1)
        .margin({ top: 8, bottom: 8 })
        .backgroundColor(AppColors.DIVIDER)
      this.scanOption('扫描 UPnP / DLNA', AppIconName.LAN, () => {
        this.scanNetwork(false);
      })
      this.scanOption('自动扫描所有网络', AppIconName.SEARCH, () => {
        this.scanNetwork(true);
      })
      if (this.scanning) {
        Row({ space: 8 }) {
          LoadingProgress()
            .width(18)
            .height(18)
            .color(AppColors.accent(this.accentColor))
          Text(this.scanMessage)
            .fontSize(AppTypography.CAPTION)
            .fontColor(AppColors.TEXT_SECONDARY)
        }
        .width('100%')
        .padding({ top: 8 })
      } else if (this.scanMessage.length > 0) {
        Text(this.scanMessage)
          .width('100%')
          .fontSize(AppTypography.CAPTION)
          .fontColor(AppColors.TEXT_SECONDARY)
          .padding({ top: 8 })
      }
      ForEach(this.discoveredServices, (service: DiscoveredService) => {
        this.discoveredServiceRow(service)
      }, (service: DiscoveredService) => `${service.host}:${service.port}`)
    }
    .width('100%')
    .padding({ left: AppSpacing.PAGE_HORIZONTAL, right: AppSpacing.PAGE_HORIZONTAL,
      top: 20, bottom: 32 })
  }

  @Builder
  private formLabel(label: string) {
    Text(label)
      .width(104)
      .fontSize(AppTypography.BODY)
      .fontColor(AppColors.TEXT_SECONDARY)
      .maxLines(1)
  }

  @Builder
  private horizontalFieldLabel(label: string, required: boolean, hasError: boolean = false) {
    Column({ space: 2 }) {
      Text(label)
        .fontSize(AppTypography.BODY)
        .fontWeight(FontWeight.Medium)
        .fontColor(hasError ? AppColors.ERROR_TEXT : AppColors.TEXT_SECONDARY)
      Text(required ? '必填' : '选填')
        .fontSize(AppTypography.META)
        .fontColor(hasError ? AppColors.ERROR_TEXT : AppColors.TEXT_MUTED)
    }
    .width(104)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private advancedSelectRow(title: string, options: string[], kind: AdvancedSelectKind) {
    Row({ space: 10 }) {
      Text(title)
        .width(104)
        .fontSize(AppTypography.BODY)
        .fontColor(AppColors.TEXT_SECONDARY)
        .maxLines(1)
      Button() {
        Row({ space: 8 }) {
          Text(options[this.advancedSelectedIndex(kind)])
            .fontSize(AppTypography.INPUT)
            .fontColor(AppColors.TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          AppIcon({ name: AppIconName.EXPAND_MORE, iconSize: 18, color: AppColors.ICON_SECONDARY })
        }
        .width('100%')
      }
        .type(ButtonType.Normal)
        .height(40)
        .layoutWeight(1)
        .padding({ left: 12, right: 8 })
        .backgroundColor(Color.Transparent)
        .border({ width: { bottom: 1 }, color: AppColors.OUTLINE })
        .borderRadius(AppRadius.NONE)
        .accessibilityText(`${title}，当前为${options[this.advancedSelectedIndex(kind)]}`)
        .bindMenu(this.advancedSelectMenuItems(options, kind), {
          placement: Placement.BottomRight,
          borderRadius: AppRadius.CONTROL,
          backgroundColor: AppColors.SURFACE_RAISED
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  private advancedSelectedIndex(kind: AdvancedSelectKind): number {
    if (kind === AdvancedSelectKind.FTP_SECURITY) {
      return this.ftpSecurityMode === FtpSecurityMode.PLAIN ? 1 :
        this.ftpSecurityMode === FtpSecurityMode.EXPLICIT_TLS ? 2 :
          this.ftpSecurityMode === FtpSecurityMode.IMPLICIT_TLS ? 3 : 0;
    }
    if (kind === AdvancedSelectKind.FTP_DATA_CONNECTION) {
      return this.ftpPassiveMode === FtpPassiveMode.PASSIVE ? 1 :
        this.ftpPassiveMode === FtpPassiveMode.ACTIVE ? 2 : 0;
    }
    if (kind === AdvancedSelectKind.FTP_ENCODING) {
      for (let index: number = 0; index < FTP_ENCODING_VALUES.length; index++) {
        if (FTP_ENCODING_VALUES[index] === this.ftpEncoding) {
          return index;
        }
      }
      return 0;
    }
    if (kind === AdvancedSelectKind.SFTP_HOST_KEY) {
      return this.sftpHostKeyPolicy === SftpHostKeyPolicy.STRICT ? 1 : 0;
    }
    return this.nfsVersion === 'nfs3' ? 1 : this.nfsVersion === 'nfs4' ? 2 : 0;
  }

  private applyAdvancedSelection(kind: AdvancedSelectKind, index: number): void {
    if (kind === AdvancedSelectKind.FTP_SECURITY) {
      this.ftpSecurityMode = index === 1 ? FtpSecurityMode.PLAIN :
        index === 2 ? FtpSecurityMode.EXPLICIT_TLS :
          index === 3 ? FtpSecurityMode.IMPLICIT_TLS : FtpSecurityMode.AUTO;
      return;
    }
    if (kind === AdvancedSelectKind.FTP_DATA_CONNECTION) {
      this.ftpPassiveMode = index === 1 ? FtpPassiveMode.PASSIVE :
        index === 2 ? FtpPassiveMode.ACTIVE : FtpPassiveMode.AUTO;
      return;
    }
    if (kind === AdvancedSelectKind.FTP_ENCODING) {
      this.ftpEncoding = index >= 0 && index < FTP_ENCODING_VALUES.length ? FTP_ENCODING_VALUES[index] : 'auto';
      return;
    }
    if (kind === AdvancedSelectKind.SFTP_HOST_KEY) {
      this.sftpHostKeyPolicy = index === 1 ? SftpHostKeyPolicy.STRICT : SftpHostKeyPolicy.ASK;
      return;
    }
    this.nfsVersion = index === 1 ? 'nfs3' : index === 2 ? 'nfs4' : 'auto';
  }

  private advancedSelectMenuItems(options: string[], kind: AdvancedSelectKind): MenuElement[] {
    const items: MenuElement[] = [];
    const selectedIndex: number = this.advancedSelectedIndex(kind);
    for (let index: number = 0; index < options.length; index++) {
      const optionIndex: number = index;
      items.push({
        value: index === selectedIndex ? `✓  ${options[index]}` : options[index],
        action: () => {
          this.applyAdvancedSelection(kind, optionIndex);
        }
      });
    }
    return items;
  }

  @Builder
  private advancedOptionsSection() {
    if (this.selectedProtocol === RemoteProtocol.SMB || this.selectedProtocol === RemoteProtocol.FTP ||
      this.selectedProtocol === RemoteProtocol.SFTP || this.selectedProtocol === RemoteProtocol.NFS) {
      Column({ space: 14 }) {
            if (this.selectedProtocol === RemoteProtocol.SMB) {
              Row({ space: 10 }) {
                this.horizontalFieldLabel('工作组', false)
                TextInput({ text: this.smbWorkgroup, placeholder: 'WORKGROUP' })
                  .height(40)
                  .fontSize(AppTypography.INPUT)
                  .fontColor(AppColors.TEXT_PRIMARY)
                  .placeholderColor(AppColors.TEXT_MUTED)
                  .backgroundColor(Color.Transparent)
                  .border({ width: { bottom: 1 }, color: this.inputBorderColor('workgroup') })
                  .borderRadius(AppRadius.NONE)
                  .padding({ left: 0, right: 0 })
                  .layoutWeight(1)
                  .onFocus(() => {
                    this.focusedField = 'workgroup';
                  })
                  .onBlur(() => {
                    this.focusedField = '';
                  })
                  .onChange((value: string) => {
                    this.smbWorkgroup = value;
                  })
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
            }

            if (this.selectedProtocol === RemoteProtocol.FTP) {
              this.advancedSelectRow('传输安全', [
                '自动',
                'FTP（不加密）',
                '显式 FTPS',
                '隐式 FTPS'
              ], AdvancedSelectKind.FTP_SECURITY)

              this.advancedSelectRow('数据连接', [
                '自动',
                '被动模式',
                '主动模式'
              ], AdvancedSelectKind.FTP_DATA_CONNECTION)

              this.advancedSelectRow('文件名编码', FTP_ENCODING_OPTIONS, AdvancedSelectKind.FTP_ENCODING)
            }

            if (this.selectedProtocol === RemoteProtocol.SFTP) {
              this.advancedSelectRow('主机指纹', [
                '首次连接时确认',
                '严格匹配'
              ], AdvancedSelectKind.SFTP_HOST_KEY)
              if (this.sftpHostKeyPolicy === SftpHostKeyPolicy.STRICT) {
                Row({ space: 10 }) {
                  this.horizontalFieldLabel('信任指纹', true)
                  TextInput({ text: this.sftpFingerprint, placeholder: 'SHA256:aa:bb:…' })
                    .id('network-form-sftp-fingerprint')
                    .height(40)
                    .fontSize(AppTypography.INPUT)
                    .fontColor(AppColors.TEXT_PRIMARY)
                    .placeholderColor(AppColors.TEXT_MUTED)
                    .backgroundColor(AppColors.SURFACE_RAISED)
                    .borderRadius(AppRadius.SMALL)
                    .layoutWeight(1)
                    .onChange((value: string) => { this.sftpFingerprint = value; })
                }
              }
            }

            if (this.selectedProtocol === RemoteProtocol.NFS) {
              this.advancedSelectRow('NFS 版本', [
                '自动检测',
                'NFSv3',
                'NFSv4'
              ], AdvancedSelectKind.NFS_VERSION)
            }
      }
      .width('100%')
    }
  }

  @Builder
  private detailsSheet() {
    Scroll() {
      Column({ space: 16 }) {
      AppSheetHeader({
        title: this.formTitle()
      })
      .padding({ bottom: 10 })

      Row({ space: 10 }) {
        this.horizontalFieldLabel('名称', false)
        TextInput({ text: this.formName,
          placeholder: '家庭服务器' })
          .id('network-form-name')
          .enterKeyType(EnterKeyType.Next)
          .height(40)
          .fontSize(AppTypography.INPUT)
          .fontColor(AppColors.TEXT_PRIMARY)
          .placeholderColor(AppColors.TEXT_MUTED)
          .backgroundColor(Color.Transparent)
          .border({ width: { bottom: 1 }, color: this.inputBorderColor('name') })
          .borderRadius(AppRadius.NONE)
          .padding({ left: 0, right: 0 })
          .layoutWeight(1)
          .onFocus(() => {
            this.focusedField = 'name';
          })
          .onBlur(() => {
            this.focusedField = '';
          })
          .onChange((value: string) => {
            this.formName = value;
          })
          .onSubmit((_enterKey: EnterKeyType) => {
            this.focusFormField('host');
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Column({ space: 6 }) {
        Row({ space: 10 }) {
          this.horizontalFieldLabel(this.selectedProtocol === RemoteProtocol.WEBDAV ? 'URL' : '服务器', true,
            this.formHostError.length > 0)
          TextInput({ text: this.formHost,
            placeholder: this.selectedProtocol === RemoteProtocol.WEBDAV ? 'example.com' :
                this.serverAddressPlaceholder() })
            .id('network-form-host')
            .enterKeyType(EnterKeyType.Next)
            .height(40)
            .fontSize(AppTypography.INPUT)
            .fontColor(AppColors.TEXT_PRIMARY)
            .placeholderColor(AppColors.TEXT_MUTED)
            .backgroundColor(Color.Transparent)
            .border({ width: { bottom: this.formHostError.length > 0 ? 2 : 1 },
              color: this.inputBorderColor('host') })
            .borderRadius(AppRadius.NONE)
            .padding({ left: 0, right: 0 })
            .layoutWeight(1)
            .onFocus(() => {
              this.focusedField = 'host';
            })
            .onBlur(() => {
              this.focusedField = '';
              if (this.selectedProtocol === RemoteProtocol.WEBDAV) {
                const rawValue: string = this.lastWebDavRawValue.length > 0 ?
                  this.lastWebDavRawValue : this.formHost;
                this.syncWebDavUrlFields(rawValue, true);
              } else {
                this.syncServerAddressFields();
              }
            })
            .onChange((value: string) => {
              if (this.selectedProtocol === RemoteProtocol.WEBDAV) {
                this.lastWebDavRawValue = value;
              }
              this.formHost = value;
              this.formHostError = '';
              this.detectedWebScheme = '';
              this.testMessage = '';
            })
            .onSubmit((_enterKey: EnterKeyType) => {
              if (this.selectedProtocol !== RemoteProtocol.WEBDAV) {
                this.syncServerAddressFields();
              }
              this.focusFormField(this.selectedProtocol === RemoteProtocol.NFS ? 'port' : 'username');
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      if (this.selectedProtocol === RemoteProtocol.WEBDAV) {
        Row() {
          Text('HTTPS')
            .fontSize(AppTypography.BODY)
            .fontColor(AppColors.TEXT_PRIMARY)
            .layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: this.webDavHttps })
            .id('network-form-https')
            .onChange((isOn: boolean) => {
              this.webDavHttps = isOn;
              this.detectedWebScheme = '';
              this.testMessage = '';
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }

      if (this.selectedProtocol !== RemoteProtocol.NFS) {
        Row({ space: 10 }) {
          this.horizontalFieldLabel('用户名', false)
          TextInput({ text: this.formUsername, placeholder: '用户名' })
            .id('network-form-username')
            .enterKeyType(EnterKeyType.Next)
            .height(40)
            .fontSize(AppTypography.INPUT)
            .fontColor(AppColors.TEXT_PRIMARY)
            .placeholderColor(AppColors.TEXT_MUTED)
            .backgroundColor(Color.Transparent)
            .border({ width: { bottom: 1 }, color: this.inputBorderColor('username') })
            .borderRadius(AppRadius.NONE)
            .padding({ left: 0, right: 0 })
            .layoutWeight(1)
            .onFocus(() => {
              this.focusedField = 'username';
            })
            .onBlur(() => {
              this.focusedField = '';
            })
            .onChange((value: string) => {
              this.formUsername = value;
            })
            .onSubmit((_enterKey: EnterKeyType) => {
              this.focusFormField('password');
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Row({ space: 10 }) {
          this.horizontalFieldLabel('密码', false)
          TextInput({ text: this.formPassword, placeholder: '密码' })
            .id('network-form-password')
            .enterKeyType(EnterKeyType.Next)
            .type(InputType.Password)
            .height(40)
            .fontSize(AppTypography.INPUT)
            .fontColor(AppColors.TEXT_PRIMARY)
            .placeholderColor(AppColors.TEXT_MUTED)
            .backgroundColor(Color.Transparent)
            .border({ width: { bottom: 1 }, color: this.inputBorderColor('password') })
            .borderRadius(AppRadius.NONE)
            .padding({ left: 0, right: 0 })
            .layoutWeight(1)
            .onFocus(() => {
              this.focusedField = 'password';
            })
            .onBlur(() => {
              this.focusedField = '';
            })
            .onChange((value: string) => {
              this.formPassword = value;
            })
            .onSubmit((_enterKey: EnterKeyType) => {
              this.focusFormField('port');
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }

      Column() {
        Column({ space: 6 }) {
          Row({ space: 10 }) {
            this.horizontalFieldLabel('端口', false, this.formPortError.length > 0)
            TextInput({ text: this.formPort, placeholder: this.portPlaceholder() })
              .id('network-form-port')
              .enterKeyType(EnterKeyType.Next)
              .type(InputType.Number)
              .height(40)
              .fontSize(AppTypography.INPUT)
              .fontColor(AppColors.TEXT_PRIMARY)
              .placeholderColor(AppColors.TEXT_MUTED)
              .backgroundColor(Color.Transparent)
              .border({ width: { bottom: this.formPortError.length > 0 ? 2 : 1 },
                color: this.inputBorderColor('port') })
              .borderRadius(AppRadius.NONE)
              .padding({ left: 0, right: 0 })
              .layoutWeight(1)
              .onFocus(() => {
                this.focusedField = 'port';
              })
              .onBlur(() => {
                this.focusedField = '';
              })
              .onChange((value: string) => {
                this.formPort = value;
                this.formPortError = '';
                this.detectedWebScheme = '';
                this.testMessage = '';
              })
              .onSubmit((_enterKey: EnterKeyType) => {
                this.focusFormField('path');
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }

      Column() {
        Row({ space: 10 }) {
          this.horizontalFieldLabel(this.pathLabel(), false,
            this.formPathError.length > 0)
          TextInput({ text: this.formPath, placeholder: this.pathPlaceholder() })
            .id('network-form-path')
            .enterKeyType(EnterKeyType.Done)
            .height(40)
            .fontSize(AppTypography.INPUT)
            .fontColor(AppColors.TEXT_PRIMARY)
            .placeholderColor(AppColors.TEXT_MUTED)
            .backgroundColor(Color.Transparent)
            .border({ width: { bottom: this.formPathError.length > 0 ? 2 : 1 },
              color: this.inputBorderColor('path') })
            .borderRadius(AppRadius.NONE)
            .padding({ left: 0, right: 0 })
            .layoutWeight(1)
            .onFocus(() => {
              this.focusedField = 'path';
            })
            .onBlur(() => {
              this.focusedField = '';
              if (this.selectedProtocol === RemoteProtocol.WEBDAV) {
                const rawValue: string = this.lastWebDavPathValue;
                this.formPath = this.webDavPathForDisplay(rawValue.length > 0 ? rawValue : this.formPath);
              }
            })
            .onChange((value: string) => {
              this.formPath = value;
              if (this.selectedProtocol === RemoteProtocol.WEBDAV) {
                this.lastWebDavPathValue = value;
                this.webDavPathEdited = true;
              }
              this.formPathError = '';
            })
            .onSubmit((_enterKey: EnterKeyType) => {
              this.saveServer();
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }

      this.advancedOptionsSection()

          Row({ space: 10 }) {
        Button() {
          Row({ space: 5 }) {
            AppIcon({ name: AppIconName.CHECK_CIRCLE, iconSize: 18,
              color: AppColors.accent(this.accentColor) })
            Text(this.testing ? '测试中' : '测试')
              .fontSize(AppTypography.BODY)
              .fontColor(AppColors.accent(this.accentColor))
          }
        }
          .type(ButtonType.Normal)
          .height(40)
          .layoutWeight(1)
          .fontSize(AppTypography.BODY)
          .fontColor(AppColors.accent(this.accentColor))
          .backgroundColor(Color.Transparent)
          .borderRadius(AppRadius.CONTROL)
          .enabled(!this.testing && !this.saving)
          .opacity(this.testing ? 0.55 : 1)
          .accessibilityText(this.testing ? '测试中' : '测试连接')
          .onClick(() => {
            this.testConnection();
          })
        Button(this.saving ? '正在保存' : '保存')
          .type(ButtonType.Normal)
          .height(40)
          .layoutWeight(1)
          .fontSize(AppTypography.BODY)
          .fontColor(AppColors.accent(this.accentColor))
          .backgroundColor(Color.Transparent)
          .borderRadius(AppRadius.CONTROL)
          .enabled(!this.saving)
          .opacity(this.saving ? 0.55 : 1)
          .onClick(() => {
            this.saveServer();
          })
          }
          .width('100%')
          .margin({ top: 8 })
      }
      .width('100%')
      .padding({ left: AppSpacing.PAGE_HORIZONTAL, right: AppSpacing.PAGE_HORIZONTAL,
        top: 20, bottom: 32 })
    }
    .width('100%')
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.None)
  }

  @Builder
  private addSheetContent() {
    AppSheetSurface() {
      if (this.addStep === NetworkAddStep.PROTOCOL) {
        this.protocolSheet()
      } else {
        this.detailsSheet()
      }
    }
  }

  build() {
    Column() {
      AppToolbar({ title: '网络' }) {
        this.toolbarActions()
      }

        if (this.loading) {
        Column() {
          LoadingProgress()
            .width(28)
            .height(28)
            .color(AppColors.accent(this.accentColor))
        }
        .width('100%')
        .height(0)
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        } else if (this.loadFailure.length > 0) {
        Column({ space: 10 }) {
          Text(this.loadFailure)
            .fontSize(AppTypography.BODY)
            .fontColor(AppColors.TEXT_SECONDARY)
          Button('重试')
            .type(ButtonType.Normal)
            .height(36)
            .fontSize(AppTypography.BODY)
            .fontColor(AppColors.accent(this.accentColor))
            .backgroundColor(AppColors.SURFACE_RAISED)
            .borderRadius(AppRadius.CONTROL)
            .onClick(() => {
              this.loadServers();
            })
        }
        .width('100%')
        .height(0)
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        } else if (this.servers.length === 0) {
        Column() {
          this.emptyState()
        }
        .width('100%')
        .height(0)
        .layoutWeight(1)
        } else {
        List({ space: MediaLayout.NETWORK_SERVER_ITEM_GAP, scroller: this.serverListScroller }) {
          ForEach(this.servers, (server: NetworkServerEntry) => {
            ListItem() {
              this.serverRow(server)
            }
          }, (server: NetworkServerEntry) => this.serverListKey(server))
        }
        .width('100%')
        .height(0)
        .layoutWeight(1)
        .padding({ top: MediaLayout.BROWSER_TOP_INSET, bottom: AppSpacing.PAGE_BOTTOM })
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.None)
        .onScrollIndex((first: number, _last: number, _center: number) => {
          this.serverListScrollIndex = first;
        })
        .bindSheet(this.serverSheetVisible!!, this.serverSheetContent(), {
          height: SheetSize.FIT_CONTENT,
          radius: { topLeft: AppRadius.SHEET, topRight: AppRadius.SHEET },
          effectEdge: 0,
          showClose: false
        })
        }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
    .bindSheet(this.addSheetVisible!!, this.addSheetContent(), {
      height: SheetSize.FIT_CONTENT,
      radius: { topLeft: AppRadius.SHEET, topRight: AppRadius.SHEET },
      effectEdge: 0,
      showClose: false
    })
  }
}
