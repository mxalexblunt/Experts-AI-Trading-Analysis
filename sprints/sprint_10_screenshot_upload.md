# Sprint 10 - Screenshot Upload

## Goal

Add single chart screenshot upload for AI visual interpretation.

## Checklist

- [x] Add `image_picker` integration for camera and photo library.
- [x] Configure iOS permission descriptions with Experts-specific purpose text.
- [x] Limit selection to one image for MVP.
- [x] Apply `maxWidth: 1200`, `maxHeight: 1200`, and `imageQuality: 85`.
- [x] Add screenshot preview and remove action.
- [x] Handle permission denied and picker cancellation states.

## Acceptance Criteria

- User can attach one clear chart screenshot.
- User can remove the screenshot before analysis.
- Permission copy is specific to chart screenshots for AI market analysis.
- Screenshot data is not sent to AI before consent is granted.

