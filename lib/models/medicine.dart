class Medicine {
  const Medicine({
    required this.id,
    required this.name,
    required this.genericName,
    required this.manufacturer,
    required this.category,
    required this.priceBdt,
    required this.dosageForm,
    required this.strength,
    required this.imageUrl,
    required this.uses,
    required this.description,
  });

  final int id;
  final String name;
  final String genericName;
  final String manufacturer;
  final String category;
  final double priceBdt;
  final String dosageForm;
  final String strength;
  final String imageUrl;
  final String uses;
  final String description;

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] as int,
      name: json['name'] as String,
      genericName: json['generic_name'] as String,
      manufacturer: json['manufacturer'] as String,
      category: json['category'] as String,
      priceBdt: (json['price_bdt'] as num).toDouble(),
      dosageForm: json['dosage_form'] as String,
      strength: json['strength'] as String,
      imageUrl: json['image_url'] as String,
      uses: json['uses'] as String,
      description: json['description'] as String,
    );
  }
}
