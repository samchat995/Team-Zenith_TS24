class StoryQuestion {
  final int id;
  final String characterName;
  final int age;
  final String location;
  final String locationBadge;
  final String visualDescription;
  final String? titleEn;
  final String? titleHi;
  final String? titleAs;
  final String storyEn;
  final String storyHi;
  final String storyAs;
  final String questionEn;
  final String questionHi;
  final String questionAs;
  final bool expectedYes;

  const StoryQuestion({
    required this.id,
    this.characterName = 'Resident',
    this.age = 68,
    this.location = 'North East',
    this.locationBadge = 'NER',
    this.visualDescription = 'Elderly resident',
    this.titleEn,
    this.titleHi,
    this.titleAs,
    required this.storyEn,
    required this.storyHi,
    required this.storyAs,
    required this.questionEn,
    required this.questionHi,
    required this.questionAs,
    this.expectedYes = true,
  });

  String getTitle(String lang) {
    if (lang == 'hi') return titleHi ?? '$characterName, $age ($locationBadge)';
    if (lang == 'as') return titleAs ?? '$characterName, $age ($locationBadge)';
    return titleEn ?? '$characterName, $age ($locationBadge)';
  }

  String getStory(String lang) {
    if (lang == 'hi') return storyHi;
    if (lang == 'as') return storyAs;
    return storyEn;
  }

  String getQuestion(String lang) {
    if (lang == 'hi') return questionHi;
    if (lang == 'as') return questionAs;
    return questionEn;
  }
}

class InitialAssessmentResponseItem {
  final int questionId;
  final String characterName;
  final String location;
  final String questionText;
  final String storySummary;
  final String answer; // "Yes" or "No"
  final String language;
  final DateTime answeredAt;

  InitialAssessmentResponseItem({
    required this.questionId,
    required this.characterName,
    required this.location,
    required this.questionText,
    required this.storySummary,
    required this.answer,
    required this.language,
    DateTime? answeredAt,
  }) : answeredAt = answeredAt ?? DateTime.now();

  Map<String, dynamic> toMap(String assessmentId) => {
    'id': '${assessmentId}_q$questionId',
    'assessment_id': assessmentId,
    'question_id': questionId,
    'character_name': characterName,
    'location': location,
    'question_text': questionText,
    'story_summary': storySummary,
    'answer': answer,
    'language': language,
    'answered_at': answeredAt.toIso8601String(),
  };

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'character_name': characterName,
    'location': location,
    'question_text': questionText,
    'story_summary': storySummary,
    'answer': answer,
    'language': language,
  };

  factory InitialAssessmentResponseItem.fromMap(Map<String, dynamic> map) {
    return InitialAssessmentResponseItem(
      questionId: map['question_id'] as int? ?? 1,
      characterName: map['character_name'] as String? ?? '',
      location: map['location'] as String? ?? '',
      questionText: map['question_text'] as String? ?? '',
      storySummary: map['story_summary'] as String? ?? '',
      answer: map['answer'] as String? ?? 'No',
      language: map['language'] as String? ?? 'en',
      answeredAt: map['answered_at'] != null ? DateTime.parse(map['answered_at']) : DateTime.now(),
    );
  }
}

class AssessmentSession {
  final String id;
  final String patientId;
  final int totalQuestions;
  final int correctAnswers;
  final int skippedCount;
  final double scorePercent;
  final DateTime completedAt;

  AssessmentSession({
    required this.id,
    required this.patientId,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.skippedCount,
    required this.scorePercent,
    DateTime? completedAt,
  }) : completedAt = completedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'total_questions': totalQuestions,
    'correct_answers': correctAnswers,
    'skipped_count': skippedCount,
    'score_percent': scorePercent,
    'completed_at': completedAt.toIso8601String(),
  };
}

/// The exact 10 regional stories for New Patient Onboarding Assessment
const List<StoryQuestion> kInitial10Questions = [
  StoryQuestion(
    id: 1,
    characterName: 'Anima',
    age: 67,
    location: 'Jorhat, Assam',
    locationBadge: 'Jorhat, Assam',
    visualDescription: 'Elderly Assamese woman in traditional mekhela chador',
    storyEn: 'Anima is preparing for Bihu and her daughter told her that the family would visit on Sunday. She wrote the date down. A few hours later, she asked her husband again when everyone was coming. The next morning, she asked the same question once more.',
    storyHi: 'अनिमा बिहू की तैयारी कर रही हैं और उनकी बेटी ने बताया कि परिवार रविवार को आएगा। उन्होंने तारीख लिख भी ली। कुछ घंटों बाद, उन्होंने अपने पति से दोबारा पूछा कि सब कब आ रहे हैं। अगली सुबह, उन्होंने यही सवाल एक बार फिर पूछा।',
    storyAs: 'অনিমাই বিহুৰ প্ৰস্তুতি চলাইছে আৰু তেওঁৰ জীয়েকে ক’লে যে পৰিয়ালটো দেওবাৰে আহিব। তেওঁ তাৰিখটো লিখিও ৰাখিলে। কেইঘণ্টামান পিছত, তেওঁ গিৰিহঁতক পুনৰ সুধিলে সকলো কেতিয়া আহিব। পিছদিনা পুৱা, তেওঁ একেটা প্ৰশ্ন আকৌ সুধিলে।',
    questionEn: 'Like Anima, has this ever happened to you – when you forget something someone told you recently and had to ask about it again?',
    questionHi: 'क्या अनिमा की तरह आपके साथ भी कभी ऐसा हुआ है – जब हाल ही में कही गई कोई बात आप भूल गए हों और दोबारा पूछना पड़ा हो?',
    questionAs: 'অনিমাৰ দৰে, আপোনাৰ লগত কেতিয়াবা এনে ঘটিছেনে – যেতিয়া কোনোবাই অলপ আগতে কোৱা কথা পাহৰি যায় আৰু পুনৰ সুধিব লগা হয়?',
  ),
  StoryQuestion(
    id: 2,
    characterName: 'Ato',
    age: 72,
    location: 'Kohima, Nagaland',
    locationBadge: 'Kohima, Nagaland',
    visualDescription: 'Elderly Naga man at a local market in Kohima',
    storyEn: 'Ato went to the market to buy things for a family gathering. There were many items to remember and different prices to calculate. He found it difficult to keep track of everything and his son had to help him.',
    storyHi: 'अतो परिवार के समारोह के लिए सामान खरीदने बाज़ार गए। याद रखने के लिए कई सामान थे और अलग-अलग कीमतों का हिसाब लगाना था। उन्हें सब कुछ याद रखना मुश्किल लगा और उनके बेटे को उनकी मदद करनी पड़ी।',
    storyAs: 'আটোৱে ঘৰুৱা অনুষ্ঠানৰ বাবে বজাৰ কৰিবলৈ গ’ল। মনত ৰাখিবলৈ বহুতো বস্তু আছিল আৰু দামৰ হিচাপো কৰিবলগীয়া আছিল। সকলো মনত ৰখাত তেওঁৰ অসুবিধা হ’ল আৰু পুতেকে সহায় কৰিব লগা হ’ল।',
    questionEn: 'When you go shopping or have several things to arrange, does this sometimes happen to you too?',
    questionHi: 'जब आप बाज़ार जाते हैं या कई चीज़ों का इंतज़ाम करना होता है, तो क्या कभी आपके साथ भी ऐसा होता है?',
    questionAs: 'যেতিয়া আপুনি বজাৰ কৰে বা কেইবাটাও বস্তুৰ ব্যৱস্থা কৰিব লগা হয়, আপোনাৰ লগত কেতিয়াবা এনেকুৱা হয়নে?',
  ),
  StoryQuestion(
    id: 3,
    characterName: 'Meban',
    age: 69,
    location: 'Shillong, Meghalaya',
    locationBadge: 'Shillong, Meghalaya',
    visualDescription: 'Elderly Khasi man with natural Shillong hills background',
    storyEn: 'Meban usually walks to the same market every Saturday. One day, he took a familiar road but suddenly became unsure where it led. At home, he also struggled with an appliance he had used many times before.',
    storyHi: 'मेबान आम तौर पर हर शनिवार एक ही बाज़ार जाते हैं। एक दिन उन्होंने अपनी जानी-पहचानी सड़क ली लेकिन अचानक उन्हें समझ नहीं आया कि रास्ता कहाँ जा रहा है। घर पर भी, वे उस उपकरण को चलाने में उलझ गए जिसे वे पहले कई बार इस्तेमाल कर चुके थे।',
    storyAs: 'মেবানে প্ৰতি শনিবাৰে সদায় একেখন বজাৰলৈ যায়। এদিন তেওঁ চিনাকি ৰাস্তা ল’লে যদিও হঠাৎ বাটটো ক’লৈ গৈছে বুজিব নোৱাৰিলে। ঘৰতো, পূৰ্বতে বহুবাৰ ব্যৱহাৰ কৰা সঁজুলি এটা ব্যৱহাৰ কৰাত তেওঁৰ অসুবিধা হ’ল।',
    questionEn: 'Like Meban, have you ever found yourself unsure about how to do something that you usually do without any problem?',
    questionHi: 'क्या मेबान की तरह आप भी कभी किसी ऐसे काम को लेकर असमंजस में पड़े हैं, जिसे आप हमेशा आसानी से कर लेते थे?',
    questionAs: 'মেবানৰ দৰে, আপুনিও কেতিয়াবা এনে কামত অনিশ্চিত হৈ পৰিছেনে যিটো আপুনি সদায় সহজে কৰিছিল?',
  ),
  StoryQuestion(
    id: 4,
    characterName: 'Thangjam',
    age: 75,
    location: 'Imphal, Manipur',
    locationBadge: 'Imphal, Manipur',
    visualDescription: 'Elderly Manipuri man in traditional attire',
    storyEn: 'Thangjam’s family was preparing for a celebration. One morning, he asked his wife when it would happen, even though it was that very day. Later, he also became confused about which day of the week it was.',
    storyHi: 'थांगजाम का परिवार एक उत्सव की तैयारी कर रहा था। एक सुबह, उन्होंने अपनी पत्नी से पूछा कि यह कब होगा, जबकि वह उसी दिन था। बाद में, वे यह भी भूल गए कि आज हफ़्ते का कौन सा दिन है।',
    storyAs: 'থাংজামৰ পৰিয়ালে এটা উৎসৱৰ প্ৰস্তুতি চলাই আছিল। এদিন পুৱা তেওঁ পত্নীক সুধিলে উৎসৱটো কেতিয়া হ’ব, অথচ সেই দিনাই উৎসৱ আছিল। পিছত, বাৰটো কি আছিল সেই বিষয়েও তেওঁ বিভ্ৰান্ত হৈ পৰিল।',
    questionEn: 'Like Thangjam, have you ever had a moment when you were unsure about what day it was or why you had gone somewhere?',
    questionHi: 'क्या थांगजाम की तरह आपका भी कभी ऐसा पल आया है जब आप दिन भूल गए हों या यह भूल गए हों कि आप किसी जगह क्यों आए हैं?',
    questionAs: 'থাংজামৰ দৰে, আপোনাৰো কেতিয়াবা এনে ক্ষণ আহিছেনে যেতিয়া আজি কি বাৰ বা ক’লৈ কিয় আহিছে পাহৰি গৈছিল?',
  ),
  StoryQuestion(
    id: 5,
    characterName: 'Lalhmingi',
    age: 64,
    location: 'Aizawl, Mizoram',
    locationBadge: 'Aizawl, Mizoram',
    visualDescription: 'Elderly Mizo woman with an Aizawl hillside background',
    storyEn: 'Lalhmingi enjoys walking around the hilly streets near her home. Recently, she sometimes misjudges a step and finds it harder to judge how far away things are. Reading small writing on shop signs has also become difficult.',
    storyHi: 'लाल्हमिंगी को अपने घर के पास पहाड़ी सड़कों पर टहलना पसंद है। हाल ही में, कभी-कभी उनका पैर गलत पड़ जाता है और दूरी का अंदाज़ा लगाना मुश्किल हो जाता है। दुकानों के बोर्ड पर छोटे अक्षर पढ़ना भी कठिन हो गया है।',
    storyAs: 'লালহমিঙিয়ে নিজৰ ঘৰৰ ওচৰৰ পাহাৰীয়া ৰাস্তাত খোজ কাঢ়ি ভাল পায়। অলপতে, খোজ কাঢ়োঁতে তেওঁ দূৰত্ব সঠিককৈ নিৰ্ণয় কৰিব নোৱাৰা হ’ল। দোকানৰ চাইনবৰ্ডৰ সৰু আখৰ পঢ়াতো অসুবিধা হ’ল।',
    questionEn: 'Like Lalhmingi, have you ever misjudged a step or distance while walking, or found it harder to see things clearly?',
    questionHi: 'क्या लाल्हमिंगी की तरह, चलते समय कभी आपका क़दम या दूरी का अंदाज़ा गलत हुआ है, या चीज़ों को साफ़ देखने में कठिनाई हुई है?',
    questionAs: 'লালহমিঙিৰ দৰে, খোজ কাঢ়োঁতে আপোনাৰ কেতিয়াবা ভুল খোজ পৰিছেনে বা দূৰত্ব জুখিবলৈ টান পাইছেনে?',
  ),
  StoryQuestion(
    id: 6,
    characterName: 'Bimal',
    age: 70,
    location: 'Agartala, Tripura',
    locationBadge: 'Agartala, Tripura',
    visualDescription: 'Elderly Tripuri man in a friendly neighborhood setting',
    storyEn: 'Bimal enjoys talking with his neighbors about local news. Recently, he sometimes stops in the middle of a conversation because he cannot find the right word. Sometimes he describes familiar objects instead of saying their names.',
    storyHi: 'बिमल को पड़ोसियों के साथ स्थानीय ख़बरों पर बात करना पसंद है। हाल ही में, वे कभी-कभी बातचीत के बीच में रुक जाते हैं क्योंकि उन्हें सही शब्द याद नहीं आता। कभी-कभी वे जानी-पहचानी चीज़ों का नाम लेने के बजाय उनका विवरण देने लगते हैं।',
    storyAs: 'বিমলে ওচৰ-চুবুৰীয়াৰ লগত বাতৰি আলোচনা কৰি ভাল পায়। শেহতীয়াকৈ, কথাপাতি থাকোঁতে তেওঁ হঠাৎ ৰৈ যায় কাৰণ সঠিক শব্দটো মনলৈ নাহে। চিনাকি বস্তুৰ নাম পাহৰি তাৰ বিৱৰণ দিবলৈ লয়।',
    questionEn: 'When you are talking with your family or neighbors, have you also had moments like Bimal, where you know what you want to say but the word just doesn’t come to you?',
    questionHi: 'जब आप अपने परिवार या पड़ोसियों से बात करते हैं, तो क्या बिमल की तरह आपके साथ भी ऐसा हुआ है कि आप कहना तो चाहते हैं पर शब्द याद नहीं आता?',
    questionAs: 'পৰিয়াল বা ওচৰ-চুবুৰীয়াৰ লগত কথা পাতোঁতে, বিমলৰ দৰে আপোনাৰো কিবা ক’ব খুজিও সঠিক শব্দটো মনত নপৰা হৈছেনে?',
  ),
  StoryQuestion(
    id: 7,
    characterName: 'Tashi',
    age: 66,
    location: 'Itanagar, Arunachal Pradesh',
    locationBadge: 'Itanagar, Arunachal Pradesh',
    visualDescription: 'Elderly Arunachali man in a home setting',
    storyEn: 'Tashi normally keeps his spectacles, wallet and keys in the same places. One morning, he could not find his spectacles and could not remember where he had last used them. His wife eventually found them in an unusual place.',
    storyHi: 'ताशी आम तौर पर अपना चश्मा, बटुआ और चाबियाँ तय जगह पर ही रखते हैं। एक सुबह, उन्हें अपना चश्मा नहीं मिला और वे भूल गए कि उन्होंने इसे आखिरी बार कहाँ इस्तेमाल किया था। बाद में उनकी पत्नी को वह किसी अजीब जगह मिला।',
    storyAs: 'তাশীয়ে সাধাৰণতে নিজৰ চশমা, মানিবেগ আৰু চাবি নিৰ্দিষ্ট ঠাইত ৰাখে। এদিন পুৱা তেওঁ চশমাযোৰ বিচাৰি নাপালে আৰু শেষবাৰ ক’ত থৈছিল পাহৰি গ’ল। শেষত পত্নীয়ে কোনো অস্বাভাৱিক ঠাইত চশমাযোৰ পালে।',
    questionEn: 'Like Tashi, have you also sometimes kept something somewhere unusual and then been unable to remember where you had put it?',
    questionHi: 'क्या ताशी की तरह आपने भी कभी कोई सामान किसी अनोखी जगह रख दिया और फिर याद नहीं आया कि कहाँ रखा था?',
    questionAs: 'তাশীৰ দৰে, আপুনিও কেতিয়াবা বস্তু ক’ৰবাত অচিনাকি ঠাইত থৈ পিছত ক’ত থৈছিল পাহৰি পেলাইছেনে?',
  ),
  StoryQuestion(
    id: 8,
    characterName: 'Dorjee',
    age: 73,
    location: 'Gangtok, Sikkim',
    locationBadge: 'Gangtok, Sikkim',
    visualDescription: 'Elderly Sikkimese shopkeeper in Gangtok',
    storyEn: 'Dorjee ran a small shop for many years and was always careful with money. Recently, he bought something without checking the price properly. Another day, he forgot to take care of an important household payment.',
    storyHi: 'दोरजी ने कई सालों तक एक छोटी दुकान चलाई और वे पैसों के मामले में हमेशा सावधान रहते थे। हाल ही में, उन्होंने बिना ठीक से कीमत देखे सामान खरीद लिया। दूसरे दिन, वे घर का एक ज़रूरी भुगतान करना भूल गए।',
    storyAs: 'দৰজীয়ে বহু বছৰ এখন সৰু দোকান চলাইছিল আৰু টকা-পইচাৰ হিচাপত বৰ সাৱধান আছিল। শেহতীয়াকৈ, তেওঁ ভালদৰে দাম নোচোৱাকৈ বস্তু কিনিলে। আন এদিন ঘৰৰ এটা জৰুৰী বিল দিবলৈ পাহৰি থাকিল।',
    questionEn: 'Like Dorjee, have you ever made a decision about money or an everyday matter and later wondered why you had made that choice?',
    questionHi: 'क्या दोरजी की तरह आपने कभी पैसों या किसी रोज़मर्रा के मामले में ऐसा निर्णय लिया है जिसके बाद आपको लगा हो कि ऐसा क्यों किया?',
    questionAs: 'দৰজীৰ দৰে, আপুনিও কেতিয়াবা টকা-পইচা বা দৈনন্দিন কামৰ এনেকুৱা সিদ্ধান্ত লৈছেনে যাৰ পিছত ভাবিলে যে কিয় এনে কৰিলোঁ?',
  ),
  StoryQuestion(
    id: 9,
    characterName: 'Jonali',
    age: 62,
    location: 'Dibrugarh, Assam',
    locationBadge: 'Dibrugarh, Assam',
    visualDescription: 'Elderly Assamese woman in a warm home atmosphere',
    storyEn: 'Jonali used to enjoy visiting neighbors and joining family gatherings. She especially looked forward to community celebrations and evening conversations. Recently, she often prefers to stay at home and sometimes skips gatherings she would normally enjoy.',
    storyHi: 'जोनाली को पड़ोसियों से मिलना और पारिवारिक आयोजनों में शामिल होना बहुत पसंद था। वे त्योहारों और शाम की बातचीत का बेसब्री से इंतज़ार करती थीं। हाल ही में, वे अक्सर घर पर ही रहना पसंद करती हैं और उन कार्यक्रमों में भी नहीं जातीं जिनका वे पहले आनंद लेती थीं।',
    storyAs: 'জোনালীয়ে ওচৰ-চুবুৰীয়াৰ ঘৰলৈ যাবলৈ আৰু পাৰিবাৰিক অনুষ্ঠানত যোগ দিবলৈ বৰ ভাল পাইছিল। সামাজিক উৎসৱ আৰু আড্ডালৈ তেওঁ বাট চাই আছিল। অলপতে, তেওঁ প্ৰায়ে ঘৰতে থাকি ভালপোৱা হ’ল আৰু অনুষ্ঠানবোৰ এৰাই চলিবলৈ ল’লে।',
    questionEn: 'Like Jonali, have you also found yourself staying home more often or skipping gatherings that you would normally enjoy?',
    questionHi: 'क्या जोनाली की तरह आपने भी खुद को ज़्यादातर घर पर रहते हुए या उन समारोहों में न जाते हुए पाया है जिन्हें आप पहले पसंद करते थे?',
    questionAs: 'জোনালীৰ দৰে, আপুনিও আজিকালি বেছিকৈ ঘৰতে থাকি ভালপোৱা বা পূৰ্বতে ভালপোৱা অনুষ্ঠানবোৰলৈ যাবলৈ অনিচ্ছুক হৈ পৰিছেনে?',
  ),
  StoryQuestion(
    id: 10,
    characterName: 'Neikha',
    age: 68,
    location: 'Dimapur, Nagaland',
    locationBadge: 'Dimapur, Nagaland',
    visualDescription: 'Elderly Naga woman in a serene home setting',
    storyEn: 'Neikha has always liked following the same morning routine. Recently, small changes to her routine sometimes make her unusually upset. She becomes worried or irritated when things do not happen as she expected.',
    storyHi: 'नेइखा को हमेशा अपनी एक जैसी सुबह की दिनचर्या का पालन करना पसंद रहा है। हाल ही में, उनकी दिनचर्या में छोटे-मोटे बदलाव भी उन्हें असामान्य रूप से परेशान कर देते हैं। जब चीजें उनकी उम्मीद के मुताबिक नहीं होतीं तो वे चिंतित या चिड़चिड़ी हो जाती हैं।',
    storyAs: 'নেইখাই সদায় পুৱাৰ নিৰ্দিষ্ট নিয়ম পালন কৰি ভাল পায়। শেহতীয়াকৈ, নিয়মৰ সৰু সলনি হ’লেও তেওঁ বৰ বিচলিত হৈ পৰে। কথা মতে কাম নহ’লে তেওঁ চিন্তিত বা খঙাল হৈ পৰে।',
    questionEn: 'Like Neikha, have you also noticed times when a small change in your usual routine makes you more upset or worried than it used to?',
    questionHi: 'क्या नेइखा की तरह आपने भी महसूस किया है कि दिनचर्या में छोटा सा बदलाव भी आपको पहले की तुलना में ज़्यादा परेशान या चिंतित कर देता है?',
    questionAs: 'নেইখাৰ দৰে, আপুনিও লক্ষ্য কৰিছেনে যে সাধাৰণ নিয়মৰ সৰু সলনিয়েও আপোনাক আগতকৈ বেছি চিন্তিত বা অশান্ত কৰি তোলে?',
  ),
];

