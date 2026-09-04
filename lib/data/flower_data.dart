import '../models/flower.dart';


const String _placeholderImage =
    'https://loremflickr.com/400/400/tulip,pink/all?lock=1';

final List<Flower> flowerList = [
  Flower(id: '1', name: 'Tulip Touch', price: 599, imageUrl: _placeholderImage, category: 'Flowers'),
  Flower(id: '2', name: 'Pink Romance', price: 799, imageUrl: _placeholderImage, category: 'Flowers'),
  Flower(id: '3', name: 'Lily Dream', price: 649, imageUrl: _placeholderImage, category: 'Flowers'),
  Flower(id: '4', name: 'Sweet Whisper', price: 499, imageUrl: _placeholderImage, category: 'Flowers'),

  Flower(id: '13', name: 'Classic Pink Bouquet', price: 899, imageUrl: _placeholderImage, category: 'Bouquet'),
  Flower(id: '14', name: 'Elegant Rose Bouquet', price: 1199, imageUrl: _placeholderImage, category: 'Bouquet'),
  Flower(id: '15', name: 'Pastel Mix Bouquet', price: 999, imageUrl: _placeholderImage, category: 'Bouquet'),

  // Wrappers (paper for custom bouquets)
  Flower(id: '16', name: 'Kraft Paper Wrap', price: 49, imageUrl: _placeholderImage, category: 'Wrappers'),
  Flower(id: '17', name: 'Pink Tissue Wrap', price: 39, imageUrl: _placeholderImage, category: 'Wrappers'),
  Flower(id: '18', name: 'Clear Cellophane Wrap', price: 35, imageUrl: _placeholderImage, category: 'Wrappers'),

  // Ribbon (finishing touch for custom bouquets)
  Flower(id: '19', name: 'Satin Pink Ribbon', price: 25, imageUrl: _placeholderImage, category: 'Ribbon'),
  Flower(id: '20', name: 'Lace Ribbon', price: 30, imageUrl: _placeholderImage, category: 'Ribbon'),
  Flower(id: '21', name: 'Burlap Ribbon', price: 20, imageUrl: _placeholderImage, category: 'Ribbon'),
];