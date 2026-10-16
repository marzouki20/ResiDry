// Shared display catalog. Stored status codes and user-authored data stay unchanged.
// Placeholders are matched only against complete catalog messages.
const appTranslations = <(String, String, String)>[
  (
    'Validation du véhicule requise avant attribution des missions.',
    'Vehicle approval is required before assigning missions.',
    'موافقة المركبة مطلوبة قبل إسناد المهام.'
  ),
  (
    'L’attribution dépasse la capacité approuvée du véhicule.',
    'Assignment exceeds the approved vehicle capacity.',
    'إسناد المهمة يتجاوز السعة المعتمدة للمركبة.'
  ),
  (
    'Examen administrateur requis',
    'Administrator review required',
    'يلزم فحص المسؤول'
  ),
  (
    'Preuve cohérente ; validation en attente',
    'Consistent evidence; pending approval',
    'دليل متوافق؛ بانتظار الموافقة'
  ),
  (
    'Capacité supérieure à la preuve',
    'Capacity exceeds evidence',
    'السعة تتجاوز الدليل'
  ),
  ('Capacité validée', 'Capacity approved', 'تمت الموافقة على السعة'),
  ('Preuve refusée', 'Evidence rejected', 'الدليل مرفوض'),
  ('Tunis', 'Tunis', 'تونس'),
  ('Ariana', 'Ariana', 'أريانة'),
  ('Ben Arous', 'Ben Arous', 'بن عروس'),
  ('Manouba', 'Manouba', 'منوبة'),
  ('Nabeul', 'Nabeul', 'نابل'),
  ('Zaghouan', 'Zaghouan', 'زغوان'),
  ('Bizerte', 'Bizerte', 'بنزرت'),
  ('Béja', 'Béja', 'باجة'),
  ('Jendouba', 'Jendouba', 'جندوبة'),
  ('Le Kef', 'Le Kef', 'الكاف'),
  ('Siliana', 'Siliana', 'سليانة'),
  ('Kairouan', 'Kairouan', 'القيروان'),
  ('Kasserine', 'Kasserine', 'القصرين'),
  ('Sidi Bouzid', 'Sidi Bouzid', 'سيدي بوزيد'),
  ('Sousse', 'Sousse', 'سوسة'),
  ('Monastir', 'Monastir', 'المنستير'),
  ('Mahdia', 'Mahdia', 'المهدية'),
  ('Sfax', 'Sfax', 'صفاقس'),
  ('Gafsa', 'Gafsa', 'قفصة'),
  ('Tozeur', 'Tozeur', 'توزر'),
  ('Kébili', 'Kébili', 'قبلي'),
  ('Gabès', 'Gabès', 'قابس'),
  ('Médenine', 'Médenine', 'مدنين'),
  ('Tataouine', 'Tataouine', 'تطاوين'),
  (
    'Impossible de charger les données de livraison.',
    'Could not load delivery data.',
    'تعذر تحميل بيانات التوصيل.'
  ),
  ("Scooter", "Scooter", "دراجة سكوتر"),
  (
    "Linge délicat - Récupération au casier {0}",
    "Delicate laundry - Collect from locker {0}",
    "ملابس حساسة - جمع من الخزانة {0}"
  ),
  (
    "Dépôt de linge propre prévu dans casier {0}",
    "Clean laundry drop-off planned in locker {0}",
    "إيداع الملابس النظيفة مقرر في الخزانة {0}"
  ),
  (
    "Dépot de linge propre prévu dans casier {0}",
    "Clean laundry drop-off planned in locker {0}",
    "إيداع الملابس النظيفة مقرر في الخزانة {0}"
  ),
  (
    "Livré et casier verrouillé",
    "Delivered and locker locked",
    "تم التوصيل وقفل الخزانة"
  ),
  (
    "Livreur introuvable.",
    "Driver not found.",
    "لم يتم العثور على عامل التوصيل."
  ),
  (
    "Un livreur hors service ne peut pas recevoir de mission.",
    "An off-duty driver cannot receive a mission.",
    "لا يمكن لعامل توصيل خارج الخدمة استقبال مهمة."
  ),
  (
    "Seule une mission en attente peut être assignée.",
    "Only a pending mission can be assigned.",
    "يمكن تعيين مهمة قيد الانتظار فقط."
  ),
  ("Mission introuvable.", "Mission not found.", "لم يتم العثور على المهمة."),
  (
    "La mission a été modifiée par une autre opération.",
    "The mission was changed by another operation.",
    "تم تعديل المهمة بواسطة عملية أخرى."
  ),
  (
    "La mission est déjà terminée.",
    "The mission is already completed.",
    "المهمة مكتملة بالفعل."
  ),
  ("Assigner course à {0}", "Assign mission to {0}", "تعيين مهمة إلى {0}"),
  (
    "Commande {0} assignée à {1}",
    "Mission {0} assigned to {1}",
    "تم تعيين المهمة {0} إلى {1}"
  ),
  (
    "Statut de la commande {0} mis à jour : {1}",
    "Mission {0} updated: {1}",
    "تم تحديث المهمة {0}: {1}"
  ),
  ("Déverrouiller Casier {0} ?", "Unlock locker {0}?", "فتح قفل الخزانة {0}؟"),
  (
    "Action d’ouverture IoT envoyée au casier {0}.",
    "IoT unlock request sent to locker {0}.",
    "تم إرسال طلب فتح القفل إلى الخزانة {0}."
  ),
  ("IoT connecté", "IoT connected", "إنترنت الأشياء متصل"),
  ("IoT hors ligne", "IoT offline", "إنترنت الأشياء غير متصل"),
  ("Tableau de bord", "Dashboard", "لوحة التحكم"),
  ("Gestion des casiers", "Locker management", "إدارة الخزائن"),
  ("Gestion des livreurs", "Driver management", "إدارة عمال التوصيل"),
  ("Anomalies", "Incidents", "الحوادث"),
  ("Maintenance", "Maintenance", "الصيانة"),
  ("Profil", "Profile", "الملف الشخصي"),
  ("Mon profil", "My profile", "ملفي الشخصي"),
  ("Mon casier", "My locker", "خزانتي"),
  ("Historique", "History", "السجل"),
  ("Notifications", "Notifications", "الإشعارات"),
  ("ESPACE ADMINISTRATEUR", "ADMINISTRATOR AREA", "مساحة المسؤول"),
  ("ESPACE RÉSIDENT", "RESIDENT AREA", "مساحة المقيم"),
  ("GESTION DE LA RÉSIDENCE", "RESIDENCE MANAGEMENT", "إدارة السكن"),
  ("MON ESPACE", "MY AREA", "مساحتي"),
  ("Accueil", "Home", "الرئيسية"),
  ("Fermer le menu", "Close menu", "إغلاق القائمة"),
  ("Ouvrir le menu", "Open menu", "فتح القائمة"),
  (
    "Réseau IoT opérationnel",
    "IoT network operational",
    "شبكة إنترنت الأشياء تعمل"
  ),
  ("Votre casier est protégé", "Your locker is protected", "خزانتك محمية"),
  ("Bonjour", "Hello", "مرحبًا"),
  (
    "Voici l’état de vos casiers en temps réel.",
    "Your lockers at a glance, in real time.",
    "حالة خزائنك في الوقت الفعلي."
  ),
  ("Casiers au total", "Total lockers", "إجمالي الخزائن"),
  ("Disponibles", "Available", "متاحة"),
  ("Occupés", "Occupied", "مشغولة"),
  ("En maintenance", "Under maintenance", "قيد الصيانة"),
  ("IoT connectés", "IoT connected", "أجهزة متصلة"),
  ("IoT hors ligne", "IoT offline", "أجهزة غير متصلة"),
  ("Anomalies actives", "Active incidents", "الحوادث النشطة"),
  ("Alertes récentes", "Recent alerts", "التنبيهات الأخيرة"),
  (
    "Porte ouverte depuis 12 minutes",
    "Door open for 12 minutes",
    "الباب مفتوح منذ 12 دقيقة"
  ),
  (
    "Appareil IoT déconnecté",
    "IoT device disconnected",
    "جهاز إنترنت الأشياء غير متصل"
  ),
  (
    "Humidité anormale détectée",
    "Abnormal humidity detected",
    "تم اكتشاف رطوبة غير طبيعية"
  ),
  (
    "Surveillez et gérez les équipements de la résidence.",
    "Monitor and manage the residence equipment.",
    "راقب معدات السكن وأدرها."
  ),
  (
    "Rechercher un casier, résident...",
    "Search locker or resident...",
    "ابحث عن خزانة أو مقيم..."
  ),
  ("Tous", "All", "الكل"),
  ("Connectés", "Connected", "متصلة"),
  ("Connecté", "Connected", "متصل"),
  ("Hors ligne", "Offline", "غير متصل"),
  ("Anomalie", "Incident", "حادث"),
  ("Disponible", "Available", "متاح"),
  ("Normal", "Normal", "طبيعي"),
  ("Non attribué", "Unassigned", "غير مخصص"),
  ("Voir détails", "View details", "عرض التفاصيل"),
  ("Modifier", "Edit", "تعديل"),
  ("Attribuer résident", "Assign resident", "تعيين مقيم"),
  ("Supprimer", "Delete", "حذف"),
  ("Aucun casier trouvé.", "No lockers found.", "لم يتم العثور على خزائن."),
  ("Voir le suivi IoT", "View IoT monitoring", "عرض مراقبة إنترنت الأشياء"),
  ("Anomalies & alertes", "Incidents and alerts", "الحوادث والتنبيهات"),
  (
    "Détection intelligente et suivi des événements.",
    "Intelligent detection and event tracking.",
    "الكشف الذكي وتتبع الأحداث."
  ),
  ("À traiter", "Pending", "بانتظار المعالجة"),
  (
    "2 critiques · 1 modérée",
    "2 critical · 1 moderate",
    "حالتان حرجتان · حالة متوسطة"
  ),
  ("Critique", "Critical", "حرج"),
  ("Modérée", "Moderate", "متوسط"),
  ("Élevée", "High", "مرتفع"),
  ("Prioritaire", "Priority", "أولوية"),
  (
    "Humidité anormale · 71%",
    "Abnormal humidity · 71%",
    "رطوبة غير طبيعية · 71%"
  ),
  (
    "Déconnexion du module IoT",
    "IoT module disconnected",
    "انقطاع اتصال وحدة إنترنت الأشياء"
  ),
  (
    "Variation inhabituelle du poids",
    "Unusual weight change",
    "تغير غير معتاد في الوزن"
  ),
  (
    "Tentatives d’accès répétées",
    "Repeated access attempts",
    "محاولات دخول متكررة"
  ),
  ("Résoudre", "Resolve", "حل"),
  (
    "Équipements à contrôler ou en cours de réparation.",
    "Equipment awaiting inspection or under repair.",
    "معدات تنتظر الفحص أو قيد الإصلاح."
  ),
  ("En cours", "In progress", "قيد التنفيذ"),
  (
    "Module IoT hors ligne — diagnostic nécessaire",
    "IoT module offline — diagnosis needed",
    "وحدة إنترنت الأشياء غير متصلة — يلزم التشخيص"
  ),
  ("Profil administrateur", "Administrator profile", "ملف المسؤول"),
  (
    "Gestion de la résidence et des équipements.",
    "Residence and equipment management.",
    "إدارة السكن والمعدات."
  ),
  ("Administrateur", "Administrator", "مسؤول"),
  ("Gestionnaire ResiDry", "ResiDry manager", "مسؤول ResiDry"),
  ("Résidence", "Residence", "السكن"),
  ("Résidence universitaire", "University residence", "سكن جامعي"),
  ("Réseau", "Network", "الشبكة"),
  (
    "Passerelle IoT opérationnelle",
    "IoT gateway operational",
    "بوابة إنترنت الأشياء تعمل"
  ),
  ("Supprimer le casier ?", "Delete locker?", "حذف الخزانة؟"),
  ("Annuler", "Cancel", "إلغاء"),
  ("Nouveau casier", "New locker", "خزانة جديدة"),
  ("Modifier le casier", "Edit locker", "تعديل الخزانة"),
  ("Identifiant du casier", "Locker ID", "معرف الخزانة"),
  ("Résident", "Resident", "مقيم"),
  ("Appartement", "Apartment", "الشقة"),
  ("Poids maximal (kg)", "Maximum weight (kg)", "الوزن الأقصى (كغ)"),
  ("Saisissez un poids valide", "Enter a valid weight", "أدخل وزنًا صحيحًا"),
  ("Type", "Type", "النوع"),
  ("Standard", "Standard", "عادي"),
  ("Grand", "Large", "كبير"),
  ("Contrôlé", "Climate controlled", "متحكم في المناخ"),
  ("Réfrigéré", "Refrigerated", "مبرد"),
  ("Appareil IoT activé", "IoT device enabled", "جهاز إنترنت الأشياء مفعل"),
  (
    "Suivi température / humidité",
    "Temperature / humidity monitoring",
    "مراقبة الحرارة والرطوبة"
  ),
  ("Verrou électronique", "Electronic lock", "قفل إلكتروني"),
  ("Enregistrer", "Save", "حفظ"),
  ("Casier créé.", "Locker created.", "تم إنشاء الخزانة."),
  ("Casier mis à jour.", "Locker updated.", "تم تحديث الخزانة."),
  ("Champ obligatoire", "Required field", "حقل مطلوب"),
  ("Connexion IoT", "IoT connection", "اتصال إنترنت الأشياء"),
  ("Porte", "Door", "الباب"),
  ("Ouverte", "Open", "مفتوح"),
  ("Ouvert", "Open", "مفتوح"),
  ("Fermée", "Closed", "مغلق"),
  ("Verrou", "Lock", "القفل"),
  ("Verrouillé", "Locked", "مقفل"),
  ("Déverrouillé", "Unlocked", "غير مقفل"),
  ("Poids actuel", "Current weight", "الوزن الحالي"),
  ("Poids", "Weight", "الوزن"),
  ("Température", "Temperature", "درجة الحرارة"),
  ("Humidité", "Humidity", "الرطوبة"),
  ("Dernière activité", "Last activity", "آخر نشاط"),
  ("Surveillance IoT", "IoT monitoring", "مراقبة إنترنت الأشياء"),
  ("Historique du poids", "Weight history", "سجل الوزن"),
  ("Activité de la porte", "Door activity", "نشاط الباب"),
  ("4 ouvertures", "4 openings", "4 مرات فتح"),
  (
    "Détection IA des anomalies",
    "AI incident detection",
    "كشف الحوادث بالذكاء الاصطناعي"
  ),
  (
    "Comportement anormal détecté",
    "Abnormal behavior detected",
    "تم اكتشاف سلوك غير طبيعي"
  ),
  ("Aucune anomalie détectée", "No incidents detected", "لم يتم اكتشاف حوادث"),
  ("Confiance du modèle · 96%", "Model confidence · 96%", "ثقة النموذج · 96%"),
  (
    "Votre linge, en toute sérénité.",
    "Peace of mind for your laundry.",
    "راحة البال مع العناية بملابسك."
  ),
  ("État de votre casier", "Your locker status", "حالة خزانتك"),
  ("Poids du linge", "Laundry weight", "وزن الملابس"),
  (
    "Votre linge est protégé et suivi par ResiDry.",
    "Your laundry is protected and tracked by ResiDry.",
    "ملابسك محمية وتتم متابعتها بواسطة ResiDry."
  ),
  ("Sécurisé", "Secure", "آمن"),
  ("VOTRE CASIER", "YOUR LOCKER", "خزانتك"),
  ("kg de linge", "kg of laundry", "كغ من الملابس"),
  ("Voir mon casier", "View my locker", "عرض خزانتي"),
  ("Informations du casier", "Locker information", "معلومات الخزانة"),
  ("Déverrouiller le casier", "Unlock locker", "فتح قفل الخزانة"),
  ("Verrouiller le casier", "Lock locker", "قفل الخزانة"),
  ("Suivi du poids aujourd’hui", "Today's weight tracking", "تتبع الوزن اليوم"),
  ("Cette semaine", "This week", "هذا الأسبوع"),
  ("Ce mois", "This month", "هذا الشهر"),
  ("Aujourd’hui", "Today", "اليوم"),
  ("Porte fermée", "Door closed", "الباب مغلق"),
  (
    "Linge ajouté · 5.2 kg",
    "Laundry added · 5.2 kg",
    "تمت إضافة ملابس · 5.2 كغ"
  ),
  ("Porte ouverte", "Door opened", "تم فتح الباب"),
  ("Casier verrouillé", "Locker locked", "الخزانة مقفلة"),
  ("Collecte de linge", "Laundry collection", "جمع الملابس"),
  ("Nouveau cycle de lavage", "New wash cycle", "دورة غسيل جديدة"),
  ("Casier déverrouillé", "Locker unlocked", "تم فتح قفل الخزانة"),
  (
    "Activité de votre casier C-024.",
    "Activity for your locker C-024.",
    "نشاط خزانتك C-024."
  ),
  (
    "Les informations importantes de votre casier.",
    "Important updates about your locker.",
    "تحديثات مهمة حول خزانتك."
  ),
  (
    "Votre casier est bien verrouillé.",
    "Your locker is securely locked.",
    "خزانتك مقفلة بإحكام."
  ),
  (
    "La porte est restée ouverte pendant 10 minutes.",
    "The door was left open for 10 minutes.",
    "بقي الباب مفتوحًا لمدة 10 دقائق."
  ),
  (
    "Une activité inhabituelle a été détectée.",
    "Unusual activity detected.",
    "تم اكتشاف نشاط غير معتاد."
  ),
  (
    "Le module IoT est temporairement hors ligne.",
    "The IoT module is temporarily offline.",
    "وحدة إنترنت الأشياء غير متصلة مؤقتًا."
  ),
  (
    "Du linge a été détecté dans votre casier.",
    "Laundry detected in your locker.",
    "تم اكتشاف ملابس في خزانتك."
  ),
  (
    "Vos informations personnelles et votre logement.",
    "Your personal and residence information.",
    "معلوماتك الشخصية ومعلومات سكنك."
  ),
  ("Résident · A-204", "Resident · A-204", "مقيم · A-204"),
  ("Mon casier attribué", "My assigned locker", "الخزانة المخصصة لي"),
  (
    "C-024 · Appartement A-204",
    "C-024 · Apartment A-204",
    "C-024 · الشقة A-204"
  ),
  ("Sécurité du compte", "Account security", "أمان الحساب"),
  ("Compte protégé", "Protected account", "حساب محمي"),
  ("Votre casier est verrouillé.", "Your locker is locked.", "خزانتك مقفلة."),
  (
    "Votre casier est déverrouillé.",
    "Your locker is unlocked.",
    "تم فتح قفل خزانتك."
  ),
  ("Porte laissée ouverte", "Door left open", "الباب متروك مفتوحًا"),
  ("Bienvenue chez vous", "Welcome home", "مرحبًا بك"),
  (
    "Gérez vos casiers de linge au même endroit.",
    "Manage your laundry lockers in one place.",
    "أدر خزائن ملابسك في مكان واحد."
  ),
  ("Vos casiers", "Your lockers", "خزائنك"),
  (
    "Les informations de vos casiers apparaîtront ici.",
    "Your locker information will appear here.",
    "ستظهر معلومات خزائنك هنا."
  ),
  ("Accueil livraison", "Delivery home", "الرئيسية للتوصيل"),
  (
    "Gérez vos commandes de livraison ici.",
    "Manage your delivery orders here.",
    "أدر طلبات التوصيل هنا."
  ),
  ("Vos commandes", "Your orders", "طلباتك"),
  (
    "Vos commandes de livraison attribuées apparaîtront ici.",
    "Your assigned delivery orders will appear here.",
    "ستظهر طلبات التوصيل المخصصة لك هنا."
  ),
  ("Scooter électrique", "Electric scooter", "دراجة كهربائية"),
  ("Vélo cargo", "Cargo bicycle", "دراجة شحن"),
  ("Voiture", "Car", "سيارة"),
  ("Moto", "Motorcycle", "دراجة نارية"),
  ("Vélo", "Bicycle", "دراجة هوائية"),
  ("Camionnette", "Van", "شاحنة صغيرة"),
  ("Centre-Ville", "City center", "وسط المدينة"),
  ("Zone Nord", "North area", "المنطقة الشمالية"),
  ("Zone Sud", "South area", "المنطقة الجنوبية"),
  ("Zone Est", "East area", "المنطقة الشرقية"),
  ("Zone Ouest", "West area", "المنطقة الغربية"),
  ("Métropole Complète", "Entire metropolitan area", "كامل المنطقة الحضرية"),
  ("En service", "On duty", "في الخدمة"),
  ("Hors service", "Off duty", "خارج الخدمة"),
  ("En livraison", "Delivering", "قيد التوصيل"),
  ("À récupérer", "To collect", "بانتظار الجمع"),
  ("En transit", "In transit", "قيد النقل"),
  ("En lavage", "At laundry", "في المغسلة"),
  ("En transit retour", "Return transit", "قيد النقل للعودة"),
  ("Déposé au casier", "Deposited in locker", "تم الإيداع في الخزانة"),
  ("Livré", "Delivered", "تم التوصيل"),
  ("Livraison", "Delivery", "توصيل"),
  ("Collecte", "Collection", "جمع"),
  ("Acheminement vers EcoClean", "Transport to EcoClean", "النقل إلى EcoClean"),
  (
    "Impossible de charger les données. Réessayer",
    "Could not load delivery data. Retry",
    "تعذر تحميل بيانات التوصيل. أعد المحاولة"
  ),
  (
    "Suivez la flotte de livreurs et attribuez les missions.",
    "Monitor drivers and assign missions.",
    "تابع عمال التوصيل وعيّن المهام."
  ),
  ("Livreurs inscrits", "Registered drivers", "عمال التوصيل المسجلون"),
  ("Actifs en service", "Active drivers", "عمال التوصيل النشطون"),
  ("Courses en cours", "Active trips", "رحلات جارية"),
  ("Missions livrées", "Delivered missions", "المهام المنجزة"),
  (
    "Rechercher un livreur, zone...",
    "Search driver or area...",
    "ابحث عن عامل توصيل أو منطقة..."
  ),
  ("Véhicule", "Vehicle", "المركبة"),
  ("Téléphone", "Phone", "الهاتف"),
  ("Note", "Rating", "التقييم"),
  ("Assigner course", "Assign mission", "تعيين مهمة"),
  ("Casier", "Locker", "الخزانة"),
  ("Assigner", "Assign", "تعيين"),
  ("Fermer", "Close", "إغلاق"),
  ("L'assignation a échoué.", "Assignment failed.", "تعذر تعيين المهمة."),
  ("Mes livraisons", "My deliveries", "توصيلاتي"),
  ("Accès Casiers IoT", "IoT locker access", "الوصول إلى الخزائن الذكية"),
  (
    "Impossible de charger les missions. Réessayer",
    "Could not load missions. Retry",
    "تعذر تحميل المهام. أعد المحاولة"
  ),
  (
    "Bienvenue dans votre espace livreur ResiDry.",
    "Welcome to your ResiDry driver area.",
    "مرحبًا بك في مساحة عامل التوصيل في ResiDry."
  ),
  ("Statut : En Service", "Status: On duty", "الحالة: في الخدمة"),
  ("Statut : Hors Service", "Status: Off duty", "الحالة: خارج الخدمة"),
  (
    "Prêt à recevoir des notifications de livraison",
    "Ready to receive delivery notifications",
    "جاهز لاستقبال إشعارات التوصيل"
  ),
  ("Mode pause activé", "Pause mode enabled", "وضع التوقف مفعل"),
  (
    "Vous êtes maintenant en service",
    "You are now on duty",
    "أنت الآن في الخدمة"
  ),
  ("Vous êtes hors service", "You are now off duty", "أنت الآن خارج الخدمة"),
  ("Missions du jour", "Today's missions", "مهام اليوم"),
  ("Complétées", "Completed", "مكتملة"),
  (
    "Déverrouillage Casier IoT",
    "IoT locker unlocking",
    "فتح قفل الخزانة الذكية"
  ),
  (
    "Scanner ou ouvrir à distance",
    "Scan or open remotely",
    "امسح الرمز أو افتح عن بُعد"
  ),
  ("Accéder", "Open", "فتح"),
  ("Missions récentes", "Recent missions", "المهام الأخيرة"),
  ("Voir tout", "View all", "عرض الكل"),
  (
    "Gérez vos collectes et dépôts de linge dans la résidence.",
    "Manage laundry collections and locker drop-offs.",
    "أدر جمع الملابس وإيداعها في الخزائن."
  ),
  (
    "Rechercher commande, casier, résident...",
    "Search mission, locker, resident...",
    "ابحث عن مهمة أو خزانة أو مقيم..."
  ),
  (
    "Aucune livraison trouvée.",
    "No deliveries found.",
    "لم يتم العثور على توصيلات."
  ),
  (
    "Déverrouillage à distance et contrôle de pesée.",
    "Remote unlocking and weight checks.",
    "فتح الأقفال عن بُعد والتحقق من الوزن."
  ),
  ("Apt", "Apt", "شقة"),
  ("Charge", "Load", "الحمولة"),
  ("Ouvrir", "Open", "فتح"),
  (
    "Alertes de livraison et dépôts casiers.",
    "Delivery and locker drop-off alerts.",
    "تنبيهات التوصيل والإيداع في الخزائن."
  ),
  (
    "Nouvelle mission assignée : CMD-101",
    "New mission assigned: CMD-101",
    "تم تعيين مهمة جديدة: CMD-101"
  ),
  (
    "Récupération linge Casier C-024 (A-204)",
    "Laundry collection at locker C-024 (A-204)",
    "جمع الملابس من الخزانة C-024 (A-204)"
  ),
  ("Il y a 10 min", "10 minutes ago", "منذ 10 دقائق"),
  (
    "Casier C-031 verrouillé par livreur",
    "Locker C-031 locked by driver",
    "قفل عامل التوصيل الخزانة C-031"
  ),
  (
    "Dépôt de linge propre confirmé",
    "Clean laundry drop-off confirmed",
    "تم تأكيد إيداع الملابس النظيفة"
  ),
  ("Aujourd’hui · 11:30", "Today · 11:30", "اليوم · 11:30"),
  (
    "Rappel : Récupération EcoClean Laundry",
    "Reminder: EcoClean Laundry pickup",
    "تذكير: استلام من مغسلة EcoClean"
  ),
  (
    "3 sacs de linge prêts pour livraison retour",
    "3 laundry bags ready for return delivery",
    "3 أكياس ملابس جاهزة للتوصيل للعودة"
  ),
  ("Aujourd’hui · 09:15", "Today · 09:15", "اليوم · 09:15"),
  ("Mon profil livreur", "My driver profile", "ملفي كعامل توصيل"),
  (
    "Informations professionnelles et zone de service.",
    "Professional information and service area.",
    "المعلومات المهنية ومنطقة الخدمة."
  ),
  ("Livreur ResiDry", "ResiDry driver", "عامل توصيل ResiDry"),
  ("Zone assignée", "Assigned area", "المنطقة المخصصة"),
  ("Note de service", "Service rating", "تقييم الخدمة"),
  ("Courses effectuées", "Completed trips", "الرحلات المكتملة"),
  ("livraisons", "deliveries", "توصيلات"),
  (
    "La mise à jour de la mission a échoué.",
    "The mission update failed.",
    "تعذر تحديث المهمة."
  ),
  (
    "Signal IoT reçu · Porte déverrouillée",
    "IoT signal received · Door unlocked",
    "تم استلام الإشارة وفتح قفل الباب"
  ),
  ("Confirmer", "Confirm", "تأكيد"),
  ("Toutes", "All", "الكل"),
  ("Livrées", "Delivered", "تم التوصيل"),
  (
    "L’activation de la géolocalisation est obligatoire pour exercer en tant que livreur.",
    "Location access is required to work as a driver.",
    "الوصول إلى الموقع مطلوب للعمل كعامل توصيل."
  ),
  (
    "Saisissez une capacité supérieure à 0 kg.",
    "Enter a capacity greater than 0 kg.",
    "أدخل سعة أكبر من 0 كغ."
  ),
  (
    "La capacité maximale prise en charge est de 10 000 kg.",
    "The maximum supported capacity is 10,000 kg.",
    "الحد الأقصى المدعوم للسعة هو 10000 كغ."
  ),
  (
    "GPS activé avec succès · Position initiale enregistrée.",
    "GPS enabled successfully · Initial position saved.",
    "تم تفعيل تحديد الموقع وحفظ الموقع الأولي."
  ),
  ("Configuration Livreur", "Driver setup", "إعداد عامل التوصيل"),
  ("Enregistrement...", "Saving...", "جارٍ الحفظ..."),
  ("Terminer & Commencer", "Finish and start", "إنهاء وبدء العمل"),
  ("Continuer", "Continue", "متابعة"),
  ("Type de véhicule", "Vehicle type", "نوع المركبة"),
  (
    "Sélectionnez votre moyen de transport principal pour optimiser vos tournées de livraison et de collecte.",
    "Select your main vehicle for collection and delivery rounds.",
    "اختر مركبتك الأساسية لجولات الجمع والتوصيل."
  ),
  (
    "Capacité de charge maximale",
    "Maximum carrying capacity",
    "سعة الحمولة القصوى"
  ),
  (
    "Saisissez la capacité réelle du véhicule",
    "Enter the real vehicle capacity",
    "أدخل السعة الفعلية للمركبة"
  ),
  ("Zone géographique", "Service area", "منطقة الخدمة"),
  (
    "Choisissez votre secteur d’intervention privilégié pour recevoir les missions les plus proches.",
    "Choose your preferred area to receive nearby missions.",
    "اختر منطقتك المفضلة لاستقبال المهام القريبة."
  ),
  (
    "Validation & GPS Obligatoire",
    "Confirmation and required GPS",
    "التأكيد وتفعيل تحديد الموقع"
  ),
  (
    "Le suivi GPS en temps réel est obligatoire pour recevoir vos missions de collecte et de livraison et interagir avec les casiers IoT.",
    "Real-time GPS is required to receive missions and interact with IoT lockers.",
    "تحديد الموقع المباشر مطلوب لاستقبال المهام والتعامل مع الخزائن الذكية."
  ),
  ("Récapitulatif de votre profil", "Profile summary", "ملخص الملف"),
  ("Nom", "Name", "الاسم"),
  ("Zone", "Area", "المنطقة"),
  (
    "Statut : Actif (En attente GPS)",
    "Status: Active (waiting for GPS)",
    "الحالة: نشط (بانتظار تحديد الموقع)"
  ),
  (
    "Activer la géolocalisation requise",
    "Enable required location access",
    "تفعيل الوصول المطلوب إلى الموقع"
  ),
  (
    "Géolocalisation activée & Position enregistrée.",
    "Location enabled and position saved.",
    "تم تفعيل تحديد الموقع وحفظ الموقع."
  ),
  ("ESPACE LIVREUR", "DRIVER AREA", "مساحة عامل التوصيل"),
  ("GESTION DES COURSES", "DELIVERY MANAGEMENT", "إدارة التوصيل"),
  ("Casiers IoT", "IoT lockers", "الخزائن الذكية"),
  ("Livreur en service", "Driver on duty", "عامل التوصيل في الخدمة"),
  ("Transit retour", "Return transit", "قيد النقل للعودة"),
  ("Déposé casier", "In locker", "في الخزانة"),
  ("Partenaire", "Partner", "الشريك"),
  ("Accès", "Access", "الوصول"),
  ("Récupérer", "Collect", "جمع"),
  ("Dépôt Lavage", "Laundry drop-off", "تسليم للمغسلة"),
  ("Prise en charge", "Pick up", "استلام"),
  ("Déposer casier", "Deposit in locker", "إيداع في الخزانة"),
  ("Finaliser", "Complete", "إنهاء"),
  ("Terminé", "Completed", "مكتملة"),
  ("Changer de langue", "Change language", "تغيير اللغة"),
  (
    "Veuillez saisir votre nom, votre e-mail et votre mot de passe.",
    "Please fill in your name, email, and password.",
    "يرجى إدخال الاسم والبريد الإلكتروني وكلمة المرور."
  ),
  (
    "Veuillez saisir une adresse e-mail valide.",
    "Please enter a valid email address.",
    "يرجى إدخال عنوان بريد إلكتروني صحيح."
  ),
  (
    "Le mot de passe doit contenir au moins 6 caractères.",
    "Your password must be at least 6 characters.",
    "يجب أن تتكون كلمة المرور من 6 أحرف على الأقل."
  ),
  (
    "Veuillez accepter les conditions pour créer un compte.",
    "Please accept the terms to create an account.",
    "يرجى الموافقة على الشروط لإنشاء الحساب."
  ),
  (
    "Un compte existe déjà avec cette adresse e-mail.",
    "An account with this email already exists.",
    "يوجد حساب مرتبط بهذا البريد الإلكتروني."
  ),
  (
    "Impossible de créer le compte. Veuillez réessayer.",
    "Could not create your account. Please try again.",
    "تعذر إنشاء الحساب. يرجى المحاولة مرة أخرى."
  ),
  (
    "Veuillez saisir votre e-mail et votre mot de passe.",
    "Please enter your email and password.",
    "يرجى إدخال البريد الإلكتروني وكلمة المرور."
  ),
  (
    "Aucun compte ne correspond à cette adresse e-mail.",
    "No account was found with this email.",
    "لم يتم العثور على حساب بهذا البريد الإلكتروني."
  ),
  (
    "Le mot de passe est incorrect.",
    "The password is incorrect.",
    "كلمة المرور غير صحيحة."
  ),
  (
    "Impossible de se connecter. Veuillez réessayer.",
    "Could not sign in. Please try again.",
    "تعذر تسجيل الدخول. يرجى المحاولة مرة أخرى."
  ),
  ("Langue", "Language", "اللغة"),
  ("Mot de passe oublié ?", "Forgot password?", "هل نسيت كلمة المرور؟"),
  (
    "Saisissez votre e-mail pour recevoir un lien de réinitialisation.",
    "No worries. Enter your email and we’ll send you a reset link.",
    "أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة التعيين."
  ),
  ("Adresse e-mail", "Email address", "البريد الإلكتروني"),
  ("Envoyer le lien", "Send reset link", "إرسال رابط إعادة التعيين"),
  ("Retour à la connexion", "Back to sign in", "العودة إلى تسجيل الدخول"),
  ("Bienvenue", "Welcome back", "مرحبًا بعودتك"),
  (
    "Heureux de vous revoir. Connectez-vous à votre compte.",
    "Good to see you again. Let’s get you signed in.",
    "سعداء برؤيتك مجددًا. سجّل الدخول إلى حسابك."
  ),
  ("Mot de passe", "Password", "كلمة المرور"),
  ("Saisissez votre mot de passe", "Enter your password", "أدخل كلمة المرور"),
  ("Masquer le mot de passe", "Hide password", "إخفاء كلمة المرور"),
  ("Afficher le mot de passe", "Show password", "إظهار كلمة المرور"),
  ("Connexion...", "Signing in...", "جارٍ تسجيل الدخول..."),
  ("Se connecter", "Sign in", "تسجيل الدخول"),
  ("Créer votre compte", "Create your account", "أنشئ حسابك"),
  (
    "Commencez votre expérience ResiDry dès aujourd’hui.",
    "Start your journey with ResiDry today.",
    "ابدأ رحلتك مع ResiDry اليوم."
  ),
  ("Nom complet", "Full name", "الاسم الكامل"),
  (
    "Comment devons-nous vous appeler ?",
    "How should we call you?",
    "بماذا نناديك؟"
  ),
  ("Créez un mot de passe", "Create a password", "أنشئ كلمة مرور"),
  ("Rôle", "Role", "الدور"),
  ("Livreur", "Driver", "عامل التوصيل"),
  ("Société de lavage", "Laundry company", "شركة غسيل"),
  ("J’accepte les ", "I agree to the ", "أوافق على "),
  ("Conditions d’utilisation", "Terms of Service", "شروط الاستخدام"),
  (" et la ", " and ", " و"),
  ("Politique de confidentialité", "Privacy Policy", "سياسة الخصوصية"),
  ("Création du compte...", "Creating account...", "جارٍ إنشاء الحساب..."),
  ("Créer un compte", "Create account", "إنشاء حساب"),
  ("Continuer avec Google", "Continue with Google", "المتابعة باستخدام Google"),
  ("ou continuer avec", "or continue with", "أو المتابعة باستخدام"),
  (
    "Votre compte, votre univers.",
    "Your account, your orbit.",
    "حسابك، عالمك."
  ),
  ("Nouveau sur ResiDry ? ", "New to ResiDry? ", "جديد في ResiDry؟ "),
  (
    "Vous avez déjà un compte ? ",
    "Already have an account? ",
    "لديك حساب بالفعل؟ "
  ),
  ("Déconnexion", "Sign out", "تسجيل الخروج"),
  (
    "Voulez-vous vous déconnecter de votre compte ?",
    "Do you want to sign out of your account?",
    "هل تريد تسجيل الخروج من حسابك؟"
  ),
  ("Se déconnecter", "Sign out", "تسجيل الخروج"),
  ("Bonjour{0}", "Hello{0}", "مرحبًا{0}"),
  ("Bienvenue, {0}", "Welcome, {0}", "مرحبًا، {0}"),
  (
    "{0} cas nécessitent votre attention",
    "{0} cases need your attention",
    "{0} حالات تحتاج إلى اهتمامك"
  ),
  (
    "Casier {0} marqué en maintenance.",
    "Locker {0} marked for maintenance.",
    "تم وضع الخزانة {0} قيد الصيانة."
  ),
  (
    "Anomalie {0} marquée comme résolue.",
    "Incident {0} marked as resolved.",
    "تم تحديد الحادث {0} كمحلول."
  ),
  ("Casier {0} supprimé.", "Locker {0} deleted.", "تم حذف الخزانة {0}."),
  (
    "Le casier {0} sera retiré de la liste.",
    "Locker {0} will be removed from the list.",
    "ستتم إزالة الخزانة {0} من القائمة."
  ),
  ("Casier {0}", "Locker {0}", "الخزانة {0}"),
  ("Il y a {0} min", "{0} minutes ago", "منذ {0} دقائق"),
  ("Aujourd’hui à {0}", "Today at {0}", "اليوم عند {0}"),
  ("Aujourd’hui · {0}", "Today · {0}", "اليوم · {0}"),
  ("Hier · {0}", "Yesterday · {0}", "أمس · {0}"),
  ("Lun. · {0}", "Mon. · {0}", "الاثنين · {0}"),
  ("01 oct. · {0}", "Oct 1 · {0}", "1 أكتوبر · {0}"),
  (
    "Signalé aujourd’hui · {0}",
    "Reported today · {0}",
    "تم الإبلاغ اليوم · {0}"
  ),
  ("{0} · Vérification du verrou", "{0} · Lock inspection", "{0} · فحص القفل"),
  (
    "Suivi en temps réel · {0}",
    "Real-time monitoring · {0}",
    "المراقبة المباشرة · {0}"
  ),
  (
    "Compte {0} · Gérez vos casiers ici.",
    "{0} account · Manage your laundry lockers here.",
    "حساب {0} · أدر خزائن ملابسك هنا."
  ),
  ("Assigner une mission à {0}", "Assign mission to {0}", "تعيين مهمة إلى {0}"),
  (
    "Mission {0} assignée à {1}",
    "Mission {0} assigned to {1}",
    "تم تعيين المهمة {0} إلى {1}"
  ),
  (
    "Mission {0} mise à jour : {1}",
    "Mission {0} updated: {1}",
    "تم تحديث المهمة {0}: {1}"
  ),
  (
    "Déverrouiller le casier {0} ?",
    "Unlock locker {0}?",
    "فتح قفل الخزانة {0}؟"
  ),
  (
    "Demande de déverrouillage IoT envoyée au casier {0}.",
    "IoT unlock request sent to locker {0}.",
    "تم إرسال طلب فتح القفل إلى الخزانة {0}."
  ),
  (
    "Casier {0} déverrouillé avec succès.",
    "Locker {0} unlocked successfully.",
    "تم فتح قفل الخزانة {0} بنجاح."
  ),
  (
    "Linge délicat · Récupération au casier {0}",
    "Delicate laundry · Collect from locker {0}",
    "ملابس حساسة · جمع من الخزانة {0}"
  ),
  ("Charge max. {0} kg", "Max. load {0} kg", "الحمولة القصوى {0} كغ"),
  ("RFID/NFC activé", "RFID/NFC enabled", "RFID/NFC مفعل"),
  ("RFID/NFC désactivé", "RFID/NFC disabled", "RFID/NFC غير مفعل"),
  ("IoT Connecté", "IoT connected", "إنترنت الأشياء متصل"),
  ("IoT Hors ligne", "IoT offline", "إنترنت الأشياء غير متصل"),
];

final _exactTranslations = <String, (String, String, String)>{
  for (final entry in appTranslations)
    if (!entry.$1.contains('{0}'))
      for (final source in [entry.$1, entry.$2]) source: entry,
};

final _templateEntries = appTranslations
    .where((entry) => entry.$1.contains('{0}'))
    .toList()
  ..sort((a, b) => b.$1.length.compareTo(a.$1.length));

final _messageTemplates = [
  for (final entry in _templateEntries)
    for (final source in [entry.$1, entry.$2])
      (
        RegExp('^${source.splitMapJoin(
          RegExp(r'\{\d+\}'),
          onMatch: (_) => '(.*?)',
          onNonMatch: RegExp.escape,
        )}\$'),
        entry
      ),
];

String translateDisplayText(String source, String languageCode) {
  source = switch (source) {
    'reviewRequired' => 'Examen administrateur requis',
    'consistent' => 'Preuve cohérente ; validation en attente',
    'exceedsLimit' => 'Capacité supérieure à la preuve',
    'approved' => 'Capacité validée',
    'rejected' => 'Preuve refusée',
    _ => source,
  };
  final exact = _exactTranslations[source];
  if (exact != null) return _translation(exact, languageCode);
  for (final (pattern, entry) in _messageTemplates) {
    final match = pattern.firstMatch(source);
    if (match == null) continue;
    return _translation(entry, languageCode).replaceAllMapped(
      RegExp(r'\{(\d+)\}'),
      (placeholder) => match.group(int.parse(placeholder[1]!) + 1)!,
    );
  }
  // Compound status summaries contain independently translated labels and values.
  if (source.contains(' · ')) {
    return source
        .split(' · ')
        .map((part) => translateDisplayText(part, languageCode))
        .join(' · ');
  }
  if (source.contains(', ')) {
    return source
        .split(', ')
        .map((part) => translateDisplayText(part, languageCode))
        .join(', ');
  }
  return source;
}

String _translation((String, String, String) entry, String languageCode) =>
    switch (languageCode) {
      'fr' => entry.$1,
      'ar' => entry.$3,
      _ => entry.$2,
    };
