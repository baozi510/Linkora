# Playback Native-first Capability Audit

> Scope: research and simulator-verifiable semantics only.
>
> No product UI, no real-device waiting, no implementation parity by assumption.

## Goal

For every playback capability in `test-lab/playback/native-capability-features.json`, determine what System AVPlayer and MPV already provide natively before Linkora designs or implements the feature.

## Evidence priority

System:

1. installed DevEco/HarmonyOS SDK declarations used by this checkout;
2. current official Huawei/OpenHarmony documentation for semantics/API level;
3. simulator runtime only where the native API can be exercised honestly.

MPV:

1. pinned `@mpv-ohos/mpv-arkts` source actually used by Linkora;
2. current upstream mpv manual/source;
3. mark real rendering/audio semantics DEVICE_CONFIRMATION_REQUIRED when the simulator package stub cannot execute them.

Do not use memory or naming similarity as evidence.

## Required per feature/backend fields

- native capability exists?
- exact API/property/command/event name;
- minimum API/version if known;
- accepted values/range;
- callback/event semantics;
- state restrictions;
- wrapper exposure in current Linkora dependency;
- simulator-testable?
- device confirmation required?
- mismatch against the other backend;
- current Linkora implementation status;
- recommended normalized contract semantics;
- source references.

## Verdicts

Use:

- NATIVE_VERIFIED
- NATIVE_PARTIAL
- NATIVE_ABSENT
- WRAPPER_NOT_EXPOSED
- DEVICE_CONFIRMATION_REQUIRED
- NOT_APPLICABLE

`DEVICE_CONFIRMATION_REQUIRED` means static/native capability is identified but final runtime/output semantics cannot be proven without a real target. It is not “unknown because not researched”.

## Contract rule

Do not design a fake common denominator.

For any feature:

```text
verified common semantics
-> unified Linkora contract

different native semantics
-> capability flags / backend-specific support / explicit UNSUPPORTED

native support absent or insufficient
-> only then consider Linkora-side implementation
```

## Existing baseline

Current Linkora already exposes baseline:

- configure/surface size;
- prepare;
- play/pause;
- seek;
- playback speed;
- volume;
- duration/position/buffering;
- first-frame/video-size;
- interruption pause;
- seek-complete;
- track observation;
- video-info observation.

Audit the native source for these too; existing implementation does not exempt a feature from native-first review.

## Simulator boundary

System simulator behavior may validate API call/state semantics, but codec/hardware/output results remain simulator-specific.

The simulator MPV dependency is an unavailable stub. MPV static capability research can proceed now; real MPV runtime/output semantics go to the device backlog.

## Output

Produce a machine-readable matrix plus a concise report. Do not implement feature UI or production adapters in the audit task.
