class FamilyMemberModel {
  bool? success;
  Message? message;

  FamilyMemberModel({this.success, this.message});

  FamilyMemberModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'] != null
        ? Message.fromJson(json['message'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['success'] = success;
    if (message != null) {
      data['message'] = message!.toJson();
    }
    return data;
  }
}

class Message {
  List<Accounts>? accounts;
  int? total;

  Message({this.accounts, this.total});

  Message.fromJson(Map<String, dynamic> json) {
    if (json['accounts'] != null) {
      accounts = (json['accounts'] as List)
          .map((v) => Accounts.fromJson(v))
          .toList();
    }
    total = json['total'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (accounts != null) {
      data['accounts'] = accounts!.map((v) => v.toJson()).toList();
    }
    data['total'] = total;
    return data;
  }
}

class Accounts {
  int? id;
  String? name;
  String? username;
  String? email;
  String? phone;
  String? govId;
  String? country;
  String? city;
  String? dob;
  String? address;
  String? allergies;
  String? createdAt;
  ImageUrl? imageUrl;
  int? remainingBalance;
  String? accessCode;
  bool? isAccessCodeEnable;
  List<Media>? media;

  Accounts({
    this.id,
    this.name,
    this.username,
    this.email,
    this.phone,
    this.govId,
    this.country,
    this.city,
    this.dob,
    this.createdAt,
    this.address,
    this.allergies,
    this.imageUrl,
    this.remainingBalance,
    this.accessCode,
    this.isAccessCodeEnable,
    this.media,
  });

  Accounts.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    username = json['username'];
    email = json['email'];
    phone = json['phone'];
    govId = json['gov_id'];
    country = json['country'];
    city = json['city'];
    dob = json['dob'];
    address = json['address'];
    allergies = json['allergies']?.toString();
    createdAt = json['created_at'];
    remainingBalance = json['remaining_balance'];
    accessCode = json['access_code']?.toString();
    final enable = json['is_access_code_enable'];
    isAccessCodeEnable = enable == null
        ? null
        : enable is bool
        ? enable
        : (enable.toString() == '1' ||
              enable.toString().toLowerCase() == 'true');

    // Handle image_url safely: can be Map, [], or null
    final imageUrlJson = json['image_url'];
    if (imageUrlJson is Map<String, dynamic>) {
      imageUrl = ImageUrl.fromJson(imageUrlJson);
    } else if (imageUrlJson is List) {
      // Empty list → treat as no image
      imageUrl = ImageUrl(imageUrls: [], id: []);
    } else {
      imageUrl = null;
    }

    // Handle media
    if (json['media'] != null && json['media'] is List) {
      media = (json['media'] as List).map((v) => Media.fromJson(v)).toList();
    } else {
      media = [];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['name'] = name;
    data['username'] = username;
    data['email'] = email;
    data['phone'] = phone;
    data['gov_id'] = govId;
    data['country'] = country;
    data['city'] = city;
    data['dob'] = dob;
    data['address'] = address;
    data['allergies'] = allergies;
    data['created_at'] = createdAt;
    data['remaining_balance'] = remainingBalance;
    data['access_code'] = accessCode;
    data['is_access_code_enable'] = isAccessCodeEnable;

    if (imageUrl != null && (imageUrl!.imageUrls?.isNotEmpty ?? false)) {
      data['image_url'] = imageUrl!.toJson();
    } else {
      data['image_url'] = [];
    }

    data['media'] = media?.map((v) => v.toJson()).toList() ?? [];
    return data;
  }
}

class ImageUrl {
  List<String>? imageUrls;
  List<int>? id;

  ImageUrl({this.imageUrls, this.id});

  ImageUrl.fromJson(Map<String, dynamic> json) {
    if (json['imageUrls'] is List) {
      imageUrls = (json['imageUrls'] as List).cast<String>();
    }
    if (json['id'] is List) {
      id = (json['id'] as List).cast<int>();
    }
  }

  Map<String, dynamic> toJson() {
    return {'imageUrls': imageUrls ?? [], 'id': id ?? []};
  }
}

class Media {
  int? id;
  String? modelType;
  int? modelId;
  String? uuid;
  String? collectionName;
  String? name;
  String? fileName;
  String? mimeType;
  String? disk;
  String? conversionsDisk;
  int? size;
  int? orderColumn;
  String? createdAt;
  String? updatedAt;
  String? originalUrl;
  String? previewUrl;

  Media({
    this.id,
    this.modelType,
    this.modelId,
    this.uuid,
    this.collectionName,
    this.name,
    this.fileName,
    this.mimeType,
    this.disk,
    this.conversionsDisk,
    this.size,
    this.orderColumn,
    this.createdAt,
    this.updatedAt,
    this.originalUrl,
    this.previewUrl,
  });

  Media.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    modelType = json['model_type'];
    modelId = json['model_id'];
    uuid = json['uuid'];
    collectionName = json['collection_name'];
    name = json['name'];
    fileName = json['file_name'];
    mimeType = json['mime_type'];
    disk = json['disk'];
    conversionsDisk = json['conversions_disk'];
    size = json['size'];
    orderColumn = json['order_column'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    originalUrl = json['original_url'];
    previewUrl = json['preview_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['model_type'] = modelType;
    data['model_id'] = modelId;
    data['uuid'] = uuid;
    data['collection_name'] = collectionName;
    data['name'] = name;
    data['file_name'] = fileName;
    data['mime_type'] = mimeType;
    data['disk'] = disk;
    data['conversions_disk'] = conversionsDisk;
    data['size'] = size;
    data['order_column'] = orderColumn;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['original_url'] = originalUrl;
    data['preview_url'] = previewUrl;
    return data;
  }
}
