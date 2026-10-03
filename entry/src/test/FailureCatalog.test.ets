import { describe, expect, it } from '@ohos/hypium';
import { FailureCatalog, FailureCode, LinkIssue, RecoveryAction } from 'linkora_core';

export default function failureCatalogTest(): void {
  describe('FailureCatalog', () => {
    it('mapsHttpAuthenticationAndNotFound', 0, () => {
      const unauthorized = FailureCatalog.fromHttpStatus(401)!;
      const notFound = FailureCatalog.fromHttpStatus(404)!;

      expect(unauthorized.code).assertEqual(FailureCode.NETWORK_UNAUTHORIZED);
      expect(unauthorized.retryable).assertFalse();
      expect(unauthorized.diagnosticCode).assertEqual('LNK-NET-001/401');
      expect(notFound.code).assertEqual(FailureCode.NETWORK_NOT_FOUND);
    });

    it('marksServerFailuresAsRetryable', 0, () => {
      const failure = FailureCatalog.fromHttpStatus(503)!;

      expect(failure.code).assertEqual(FailureCode.NETWORK_SERVER_FAILED);
      expect(failure.retryable).assertTrue();
      expect(failure.action).assertEqual(RecoveryAction.RETRY);
    });

    it('mapsDnsTimeoutAndTlsErrors', 0, () => {
      expect(FailureCatalog.fromNetworkError(2300006).code)
        .assertEqual(FailureCode.NETWORK_HOST_NOT_FOUND);
      expect(FailureCatalog.fromNetworkError(2300028).code)
        .assertEqual(FailureCode.NETWORK_TIMEOUT);
      expect(FailureCatalog.fromNetworkError(2300058).code)
        .assertEqual(FailureCode.NETWORK_TLS_FAILED);
    });

    it('mapsRedirectLoopsToAnEditableFailure', 0, () => {
      const failure = FailureCatalog.fromNetworkError(2300047);

      expect(failure.code).assertEqual(FailureCode.NETWORK_REDIRECT_FAILED);
      expect(failure.action).assertEqual(RecoveryAction.EDIT_SOURCE);
      expect(failure.retryable).assertFalse();
    });

    it('preservesUnsupportedDecoderFailure', 0, () => {
      const byCode = FailureCatalog.fromPlaybackError(5400106);
      const byDetail = FailureCatalog.fromPlaybackError(0, 'unsupported video decoder type');

      expect(byCode.code).assertEqual(FailureCode.MEDIA_UNSUPPORTED);
      expect(byCode.retryable).assertFalse();
      expect(byDetail.code).assertEqual(FailureCode.MEDIA_UNSUPPORTED);
    });

    it('mapsInputValidationIntoTheSameContract', 0, () => {
      const failure = FailureCatalog.fromLinkIssue(LinkIssue.EMBEDDED_CREDENTIALS);

      expect(failure.code).assertEqual(FailureCode.LINK_EMBEDDED_CREDENTIALS);
      expect(failure.action).assertEqual(RecoveryAction.EDIT_SOURCE);
    });

    it('mapsLocalScanPermissionAndSystemErrors', 0, () => {
      const permission = FailureCatalog.fromLocalScanError(201);
      const system = FailureCatalog.fromLocalScanError(14000011);

      expect(permission.code).assertEqual(FailureCode.LOCAL_SCAN_PERMISSION_DENIED);
      expect(permission.action).assertEqual(RecoveryAction.RETRY);
      expect(system.code).assertEqual(FailureCode.LOCAL_SCAN_FAILED);
    });
  });
}
