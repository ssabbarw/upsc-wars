import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

const _kMaxProfilePhotoBytes = 100 * 1024;

/// Re-encode as JPEG until size ≤ [maxBytes] by lowering quality, then
/// shrinking the long edge if needed (floor 96px).
Uint8List _jpegBytesUnderMax(
  Uint8List bytes, {
  int maxBytes = _kMaxProfilePhotoBytes,
}) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw StateError('Could not decode image');
  }

  Uint8List? smallest;
  var smallestLen = 1 << 30;

  void trackSmallest(Uint8List candidate) {
    if (candidate.length < smallestLen) {
      smallestLen = candidate.length;
      smallest = candidate;
    }
  }

  var maxLongEdge = 1024;
  while (maxLongEdge >= 96) {
    final scaled = _fitLongEdge(decoded, maxLongEdge);
    for (var q = 82; q >= 18; q -= 4) {
      final out = img.encodeJpg(scaled, quality: q);
      trackSmallest(out);
      if (out.length <= maxBytes) {
        return out;
      }
    }
    maxLongEdge = (maxLongEdge * 0.78).round();
  }

  return smallest ?? img.encodeJpg(_fitLongEdge(decoded, 96), quality: 18);
}

img.Image _fitLongEdge(img.Image src, int longEdgeMax) {
  final lw = src.width > src.height ? src.width : src.height;
  if (lw <= longEdgeMax) {
    return src;
  }
  if (src.width >= src.height) {
    return img.copyResize(src, width: longEdgeMax);
  }
  return img.copyResize(src, height: longEdgeMax);
}

/// Picks an image from the gallery, opens a circular crop UI, uploads to
/// Firebase Storage, and updates the signed-in user's profile.
///
/// **Where the URL lives:** the download URL from Storage is written to
/// [User.photoURL] via [User.updateProfile] (Firebase Authentication). That is
/// the source of truth the app reads after sign-in. The image bytes are stored
/// at `profile_photos/{uid}/avatar.jpg` in Firebase Storage (overwritten on
/// each upload). Community/presence may later copy `photoURL` into Firestore
/// when [CommunityBucketPresenceService] syncs, but Auth holds the canonical URL.
class ProfilePhotoService {
  ProfilePhotoService({FirebaseAuth? auth, FirebaseStorage? storage})
    : _auth = auth ?? FirebaseAuth.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  /// - `(true, null)` — photo updated.
  /// - `(false, null)` — user cancelled or dismissed the flow.
  /// - `(false, message)` — error.
  Future<(bool, String?)> pickCropUploadAndUpdateProfile() async {
    if (kIsWeb) {
      return (
        false,
        'Profile photo upload is not available in the browser build.',
      );
    }

    final user = _auth.currentUser;
    if (user == null) {
      return (false, 'Sign in to change your profile photo.');
    }

    try {
      final previousPhotoUrl = user.photoURL?.trim();

      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (picked == null) {
        return (false, null);
      }

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 88,
        maxWidth: 1024,
        maxHeight: 1024,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop photo',
            cropStyle: CropStyle.circle,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop photo',
            cropStyle: CropStyle.circle,
            aspectRatioLockEnabled: true,
          ),
        ],
      );
      if (cropped == null) {
        return (false, null);
      }

      final file = File(cropped.path);
      final rawBytes = await file.readAsBytes();
      final jpegBytes = _jpegBytesUnderMax(rawBytes);

      final storageRef = _storage.ref().child(
        'profile_photos/${user.uid}/avatar.jpg',
      );
      await storageRef.putData(
        jpegBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await storageRef.getDownloadURL();
      if (previousPhotoUrl != null && previousPhotoUrl.isNotEmpty) {
        await CachedNetworkImage.evictFromCache(previousPhotoUrl);
      }
      await CachedNetworkImage.evictFromCache(url);
      await user.updateProfile(photoURL: url);
      await user.reload();
      return (true, null);
    } on FirebaseException catch (e) {
      debugPrint('ProfilePhotoService: $e');
      return (false, e.message ?? 'Could not upload your photo. Try again.');
    } catch (e, st) {
      debugPrint('ProfilePhotoService: $e');
      debugPrintStack(stackTrace: st);
      return (false, 'Something went wrong. Try again.');
    }
  }
}
