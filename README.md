# Shai's Creation

## Add Product Images

1. In the project root, create this folder:

   `assets/images/`

2. Copy your image files into that folder, for example:

   ```text
   assets/images/rose.jpg
   assets/images/sunflower.jpg
   assets/images/tulip.jpg
   ```

3. The `pubspec.yaml` file registers the whole folder:

   ```yaml
   flutter:
     uses-material-design: true
     assets:
       - assets/images/
   ```

   Keep the indentation exactly as shown. Run `flutter pub get` after changing
   `pubspec.yaml`.

4. Reference an image by its path in `lib/data/flower_data.dart`:

   ```dart
   Flower(
     id: '22',
     name: 'Rose Garden',
     price: 699,
     imageUrl: 'assets/images/rose.jpg',
     category: 'Flowers',
   ),
   ```

5. The reusable `ProductImage` widget detects paths beginning with `assets/`
   and loads them with the equivalent Flutter API:

   ```dart
   Image.asset('assets/images/rose.jpg')
   ```

You can also use `Image.asset` directly in any widget. File names and paths are
case-sensitive, so the spelling must match the file exactly.
