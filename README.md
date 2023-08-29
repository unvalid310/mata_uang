# mata_uang

Then, run flutter `pub get` to get packages.

Note: If you see an error like `Class 'TfliteFlutterHelperPlugin' is not abstract and does not implement abstract member public abstract fun onRequestPermissionsResult(p0: Int, p1: Array<(out) String!>, p2: IntArray) it might be related to this issue`. To work around it, replace the `tflite_flutter_helper: ^0.3.1` dependency with the following git call:
```dart
tflite_flutter_helper:
 git:
  url: https://github.com/filofan1/tflite_flutter_helper.git
  ref: 783f15e5a87126159147d8ea30b98eea9207ac70
```
Get packages again.

Then, if you are building for Android, run the installation script below on `macOS/Linux`:

```bash ./install.sh ```

If you’re on `Windows`, run install.bat instead:

```install.bat ```
