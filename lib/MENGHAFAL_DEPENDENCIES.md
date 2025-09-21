# Dependencies untuk Fitur Menghafal

## Dependencies yang Perlu Ditambahkan

Untuk mengaktifkan fitur merekam suara di screen Menghafal, tambahkan dependencies berikut ke `pubspec.yaml`:

```yaml
dependencies:
  # ... existing dependencies ...
  
  # Untuk fitur recording audio
  record: ^5.0.4
  
  # Untuk permission handling
  permission_handler: ^11.0.1
  
  # Optional: untuk analisis audio yang lebih advanced
  # speech_to_text: ^6.6.0
  # audio_waveforms: ^1.0.5
```

## Permissions yang Perlu Ditambahkan

### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### iOS (`ios/Runner/Info.plist`)

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record your voice for pronunciation practice.</string>
```

## Setelah Dependencies Ditambahkan

1. **Uncomment kode yang di-comment** di `menghafal_screen.dart`:
   - Import statements untuk `permission_handler` dan `record`
   - `_audioRecorder` instance
   - Permission request code
   - Recording implementation

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Test pada device fisik** (recording tidak bekerja di simulator/emulator)

## Fitur yang Tersedia

### Saat Ini (Mockup Mode)
- ✅ UI lengkap untuk screen menghafal
- ✅ Animasi recording visual
- ✅ Simulasi scoring system
- ✅ Navigation between ayat
- ✅ Audio playback reference
- ⚠️ Recording belum functional (perlu dependencies)

### Setelah Dependencies Ditambahkan
- ✅ Recording audio functionality
- ✅ Permission handling
- ✅ Audio file playback
- ✅ Real audio analysis (dengan implementasi AI)

## AI Integration (Opsional)

Untuk analisis pelafalan yang lebih akurat, dapat mengintegrasikan dengan:

1. **Google Cloud Speech-to-Text API**
2. **AWS Transcribe**
3. **Azure Speech Services**
4. **Custom ML Model** untuk Arabic pronunciation

## Struktur File Audio

File recording akan disimpan di:
- Android: `/storage/emulated/0/Android/data/[app_id]/files/`
- iOS: `Application Documents Directory`

Format: `recording_[timestamp].m4a`

## Testing

Untuk test fitur recording:

1. Build pada device fisik
2. Grant microphone permission
3. Test recording → playback cycle
4. Verify file creation dan playback
5. Test scoring simulation

## Catatan Pengembangan

- Recording quality: 44.1kHz, 128kbps AAC-LC
- Max recording duration: 60 detik per ayat
- Auto-stop jika terlalu panjang
- File cleanup otomatis setelah analysis
- Offline-first approach (tidak perlu internet untuk basic recording)
