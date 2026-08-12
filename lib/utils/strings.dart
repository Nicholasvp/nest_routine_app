class Strings {
  final bool pt;

  Strings({this.pt = false});

  Strings.pt() : pt = true;

  String get(String en, String pt) => this.pt ? pt : en;

  // ── App ──
  String get appName => get('NestRoutine', 'NestRoutine');
  String get hiThere => get('Hi there!', 'Olá!');
  String get seeAll => get('See all', 'Ver tudo');
  String get today => get('Today', 'Hoje');
  String get cancel => get('Cancel', 'Cancelar');
  String get save => get('Save', 'Salvar');
  String get delete => get('Delete', 'Excluir');
  String get confirm => get('Confirm', 'Confirmar');
  String get noBabyProfile => get('No baby profile', 'Nenhum perfil de bebê');

  // ── Onboarding ──
  String get understandYourBaby => get(
    "Understand your baby's rhythm.\nPredict what comes next.\nSleep better.",
    'Entenda o ritmo do seu bebê.\nPreveja o que vem a seguir.\nDurma melhor.',
  );
  String get wePredictSleep => get('We predict when baby will sleep', 'Prevemos quando o bebê vai dormir');
  String get wePredictSleepDesc => get(
    "Our algorithm learns your baby's patterns and predicts the next nap with confidence.",
    'Nosso algoritmo aprende os padrões do seu bebê e prevê a próxima soneca com confiança.',
  );
  String get logOneTap => get('Log in one tap', 'Registre com um toque');
  String get logOneTapDesc => get(
    'Sleep, feed, and diaper changes — all available from the home screen. No deep menus.',
    'Sono, mamada e troca de fraldas — tudo disponível na tela inicial. Sem menus profundos.',
  );
  String get notificationsRightTime => get('Notifications at the right time', 'Notificações no momento certo');
  String get notificationsRightTimeDesc => get(
    'Get reminded before the next predicted nap or feeding. Never wonder "when was the last time..."',
    'Receba lembretes antes da próxima soneca ou mamada. Nunca mais se pergunte "quando foi a última vez..."',
  );
  String get setupYourBaby => get('Set up your baby', 'Configure seu bebê');
  String get setupSubtitle => get('Just the basics to get started. Everything else is optional.', 'Apenas o básico para começar. Todo o resto é opcional.');
  String get babysName => get("Baby's name", 'Nome do bebê');
  String get nameHint => get('e.g., Emma', 'Ex: Emma');
  String get dateOfBirth => get('Date of birth', 'Data de nascimento');
  String get next => get('Next', 'Próximo');
  String get getStarted => get('Get Started', 'Começar');
  String get skipSetup => get('Skip setup', 'Pular configuração');

  // ── Home ──
  String get addBabyToStart => get('Add a baby profile to start', 'Adicione um perfil de bebê para começar');
  String get tapToStopSleepTimer => get('Tap to stop sleep timer', 'Toque para parar o timer de sono');
  String get nextNap => get('Next nap', 'Próxima soneca');
  String get nextFeed => get('Next feed', 'Próxima mamada');
  String get nextDiaper => get('Next diaper', 'Próxima fralda');
  String get sleepToday => get('Sleep today', 'Sono hoje');
  String get noEventsToday => get('No events logged today yet', 'Nenhum evento registrado hoje ainda');
  String get tapActionToStart => get('Tap an action above to start!', 'Toque em uma ação acima para começar!');
  String get deleteEvent => get('Delete event?', 'Excluir evento?');
  String removeEventLog(String type) => get('Remove this $type log?', 'Remover este registro de $type?');
  String percentConfidence(int pct) => get('$pct% confidence', '$pct% de confiança');

  // ── History ──
  String get history => get('History', 'Histórico');
  String get noEventsForDay => get('No events for this day', 'Nenhum evento para este dia');

  // ── Insights ──
  String get insights => get('Insights', 'Insights');
  String get sleep => get('Sleep', 'Sono');
  String get feed => get('Feed', 'Mamada');
  String get diaper => get('Diaper', 'Fralda');
  String get avgSleepPerDay => get('Avg sleep/day', 'Média sono/dia');
  String get sleepHours => get('Sleep Hours', 'Horas de Sono');
  String get vsRecommendedSleep => get('vs Recommended Sleep', 'vs Sono Recomendado');
  String sleepingWell(int h, int m) => get(
    'Your baby is sleeping within the recommended range of ${h}h for $m months.',
    'Seu bebê está dormindo dentro da faixa recomendada de ${h}h para $m meses.',
  );
  String sleepingOff(int avg, int h, int m) => get(
    'Average sleep is ${avg}h (recommended: ${h}h for $m months)',
    'Média de sono é ${avg}h (recomendado: ${h}h para $m meses)',
  );
  String get predictions => get('Predictions', 'Previsões');
  String get noPrediction => get('No prediction', 'Sem previsão');
  String get late => get('Late', 'Atrasado');

  // ── Quick Action Bar ──
  String get awake => get('Awake', 'Acordou');
  String get sleep_ => get('Sleep', 'Dormir');
  String get feed_ => get('Feed', 'Mamar');
  String get pee => get('Pee', 'Xixi');
  String get poop => get('Poop', 'Cocô');

  // ── Sleep Sheet ──
  String get sleepTimer => get('Sleep Timer', 'Timer de Sono');
  String get logSleep => get('Log Sleep', 'Registrar Sono');
  String get adjust => get('Adjust', 'Ajustar');
  String get wakeUp => get('Wake up!', 'Acordou!');
  String get babyFellAsleep => get('Baby fell asleep', 'Bebê dormiu');
  String get manualTimeEntry => get('Manual time entry', 'Inserir horário manual');
  String get quickDuration => get('Quick duration', 'Duração rápida');
  String get fellAsleep => get('Fell asleep', 'Dormiu');
  String get wokeUp => get('Woke up', 'Acordou');
  String get adjustSleepTime => get('Adjust sleep time', 'Ajustar horário de sono');
  String minutes_(int m) => get('${m}min', '${m}min');
  String sinceTime(String t) => get('Since $t', 'Desde $t');

  // ── Feed Sheet ──
  String get logFeed => get('Log Feed', 'Registrar Mamada');
  String get breast => get('Breast', 'Peito');
  String get bottle => get('Bottle', 'Mamadeira');
  String get left => get('Left', 'Esquerdo');
  String get right => get('Right', 'Direito');
  String get both => get('Both', 'Ambos');
  String get duration => get('Duration', 'Duração');
  String get volume => get('Volume', 'Volume');
  String get nursingNow => get('Nursing now', 'Mamando agora');
  String get stopNursing => get('Stop nursing', 'Parar de mamar');
  String get babyStartedNursing => get('Baby started nursing', 'Bebê começou a mamar');
  String get breastfeedingSideDistribution => get('Breastfeeding Side Distribution', 'Distribuição Lateral da Mamada');

  // ── Diaper Sheet ──
  String get logDiaper => get('Log Diaper', 'Registrar Fralda');
  String get addDetails => get('Add details (color, texture)', 'Adicionar detalhes (cor, textura)');
  String get texture => get('Texture', 'Textura');
  String get normal => get('Normal', 'Normal');
  String get soft => get('Soft', 'Pastoso');
  String get liquid => get('Liquid', 'Líquido');
  String get dry => get('Dry', 'Ressecado');
  String get hideDetails => get('Hide details', 'Ocultar detalhes');

  // ── Time ──
  String get time => get('Time', 'Horário');

  // ── Circular Timeline ──
  String get sleeping => get('Sleeping', 'Dormindo');
  String get awake_ => get('Awake', 'Acordado');
  String get goodMorning => get('Good morning', 'Bom dia');

  // ── Sleep Window Battery ──
  String get sleepWindow => get('Sleep Window', 'Janela de Sono');
  String get sleeping_ => get('Sleeping', 'Dormindo');
  String get batteryRestoredOnWake => get('Battery will restore on wake', 'A bateria será restaurada ao acordar');
  String get registerWakeToStart => get('Log wake-up to start', 'Registre o despertar para iniciar');
  String timeForNap(int min) => get('Nap time! Window closes in $min min.', 'Hora da Soneca! A janela fecha em $min min.');
  String get windowClosed => get('Nap time! The ideal window has closed.', 'Hora da Soneca! A janela ideal já fechou.');
  String windowClosing(int min) => get('Window closing! Baby may get overtired in $min min.', 'Janela fechando! Bebê pode ficar exausto em $min min.');
  String awakeFor(int min) => get('Awake for ${min}min', 'Acordado há ${min}min');

  // ── Profile ──
  String get profile => get('Profile', 'Perfil');
  String get weeks => get('Weeks', 'Semanas');
  String get months => get('Months', 'Meses');
  String get editProfile => get('Edit Profile', 'Editar Perfil');
  String get babies => get('Babies', 'Bebês');
  String get settings => get('Settings', 'Configurações');
  String get notifications => get('Notifications', 'Notificações');
  String get removeBaby => get('Remove baby?', 'Remover bebê?');
  String removeBabyConfirm(String name) => get('All data for $name will be deleted.', 'Todos os dados de $name serão excluídos.');
  String get remove => get('Remove', 'Remover');
  String comingSoon(String f) => get('$f coming soon!', '$f em breve!');
  String get enterName => get('Enter name', 'Digite o nome');
  String get addBaby => get('Add Baby', 'Adicionar Bebê');
  String get name => get('Name', 'Nome');
  String bornDate(String d) => get('Born $d', 'Nascido em $d');
  String get language => get('Language', 'Idioma');
  String get portuguese => get('Portuguese', 'Português');
  String get english => get('English', 'Inglês');

  // ── Notifications ──
  String get notificationSettings => get('Notification Settings', 'Configurações de Notificação');
  String get appReminder => get('App Reminder', 'Lembrete do App');
  String get appReminderDesc => get('Remind me to use the app', 'Me lembrar de usar o app');
  String get appReminderTime => get('Reminder time', 'Horário do lembrete');
  String get nextSleepReminder => get('Next sleep reminder', 'Próximo lembrete de sono');
  String get nextSleepReminderDesc => get('Remind before the next predicted nap', 'Lembrar antes da próxima soneca prevista');
  String get nextFeedReminder => get('Next feed reminder', 'Próximo lembrete de mamada');
  String get nextFeedReminderDesc => get('Remind before the next predicted feeding', 'Lembrar antes da próxima mamada prevista');
  String get sleepWindowReminder => get('Sleep window alert', 'Alerta da janela de sono');
  String get sleepWindowReminderDesc => get('Alert when sleep window is closing', 'Alertar quando a janela de sono estiver fechando');
  String get diaperCheckReminder => get('Diaper check reminders', 'Lembretes de verificar fralda');
  String get peeReminder => get('Pee check', 'Verificar xixi');
  String get peeReminderDesc => get('Remind to check for pee', 'Lembrar para verificar xixi');
  String get poopReminder => get('Poop check', 'Verificar coco');
  String get poopReminderDesc => get('Remind to check for poop', 'Lembrar para verificar coco');
  String get diaperInterval => get('Check interval', 'Intervalo de verificação');
  String minutesBefore(int m) => get('$m min before', '$m min antes');
  String everyHours(int h) => get('Every $h hours', 'A cada $h horas');
  String get notificationsEnabled => get('Notifications enabled', 'Notificações ativadas');
  String get notificationsDisabled => get('Notifications disabled', 'Notificações desativadas');
  String get grantPermission => get('Grant Permission', 'Conceder Permissão');
  String get permissionRequired => get('Permission required', 'Permissão necessária');
  String get permissionRequiredDesc => get('Allow notifications to receive reminders', 'Permitir notificações para receber lembretes');
  String get saveSettings => get('Save Settings', 'Salvar Configurações');
  String get settingsSaved => get('Settings saved', 'Configurações salvas');

  // ── Subscription ──
  String get nestRoutinePro => get('Nest Routine Pro', 'Nest Routine Pro');
  String get proActive => get('ACTIVE', 'ATIVO');
  String get proUnlocked => get('All premium features unlocked', 'Todos os recursos premium desbloqueados');
  String get proUnlockCta => get('Unlock insights, predictions & more', 'Desbloqueie insights, previsões e mais');
  String get upgradeToPro => get('Upgrade to Pro', 'Tornar-se Pro');
  String get manageSubscription => get('Manage Subscription', 'Gerenciar Assinatura');
  String get restorePurchases => get('Restore Purchases', 'Restaurar Compras');
  String get purchasesRestored => get('Purchases restored successfully!', 'Compras restauradas com sucesso!');
  String get noPurchasesFound => get('No purchases found to restore.', 'Nenhuma compra encontrada para restaurar.');
  String get subscribe => get('Subscribe', 'Assinar');
  String get bestValue => get('BEST VALUE', 'MELHOR VALOR');
  String get monthly => get('Monthly', 'Mensal');
  String get yearly => get('Yearly', 'Anual');
  String get lifetime => get('Lifetime', 'Vitalício');
  String get paywallTitle => get('Nest Routine Pro', 'Nest Routine Pro');
  String get paywallSubtitle => get(
    'Unlock all premium features\nfor your baby\'s routine tracking',
    'Desbloqueie todos os recursos premium\npara o acompanhamento da rotina do seu bebê',
  );
  String get unableToLoadOfferings => get(
    'Unable to load subscription options',
    'Não foi possível carregar as opções de assinatura',
  );
  String get retry => get('Retry', 'Tentar novamente');

  // ── Account ──
  String get logout => get('Log Out', 'Sair');
  String get logoutConfirm => get('Are you sure you want to log out?', 'Tem certeza de que deseja sair?');
  String get account => get('Account', 'Conta');

  // ── Nav Bar ──
  String get navHome => get('Home', 'Início');
  String get navHistory => get('History', 'Histórico');
  String get navInsights => get('Insights', 'Insights');
  String get navProfile => get('Profile', 'Perfil');

  // ── Login ──
  String get loginWelcomeBack => get('Welcome back!', 'Bem-vindo de volta!');
  String get loginCreateAccount => get('Create your account', 'Crie sua conta');
  String get loginEmail => get('Email', 'Email');
  String get loginPassword => get('Password', 'Senha');
  String get loginEmailRequired => get('Please enter your email', 'Por favor, digite seu email');
  String get loginEmailInvalid => get('Please enter a valid email', 'Por favor, digite um email válido');
  String get loginPasswordRequired => get('Please enter your password', 'Por favor, digite sua senha');
  String get loginPasswordShort => get('Password must be at least 6 characters', 'A senha deve ter pelo menos 6 caracteres');
  String get loginSignIn => get('Sign In', 'Entrar');
  String get loginCreate => get('Create Account', 'Criar Conta');
  String get loginSignUpLink => get("Don't have an account? Sign Up", 'Não tem conta? Criar');
  String get loginSignInLink => get('Already have an account? Sign In', 'Já tem conta? Entrar');
  String get loginSuccess => get('Login successful!', 'Login realizado com sucesso!');
  String get loginAccountCreated => get('Account created! Check your email for verification.', 'Conta criada! Verifique seu email para confirmar.');
  String get loginSyncInfo => get('Your data will be synced to the cloud', 'Seus dados serão sincronizados na nuvem');
  String get loginUnexpectedError => get('An unexpected error occurred', 'Ocorreu um erro inesperado');

  // ── Analytics ──
  String get analytics => get('Analytics', 'Análises');
  String get avgNapsPerDay => get('Avg naps/day', 'Média sonecas/dia');
  String get todayLabel => get('Today', 'Hoje');
  String get nextNapLabel => get('Next Nap', 'Próxima Soneca');
  String get nextFeedLabel => get('Next Feed', 'Próxima Mamada');
  String get nextDiaperLabel => get('Next Diaper', 'Próxima Fralda');
  String get avgFeedsPerDay => get('Avg feeds/day', 'Média mamadas/dia');
  String get avgInterval => get('Avg interval', 'Intervalo médio');
  String get feedsPerDay => get('Feeds per Day', 'Mamadas por Dia');
  String avgLabel(String val) => get('Avg: $val', 'Média: $val');
  String feedsCount(int count) => get('$count feeds', '$count mamadas');
  String get milkVolumePerDay => get('Milk Volume per Day', 'Volume de Leite por Dia');
  String get avgDiapersPerDay => get('Avg diapers/day', 'Média fraldas/dia');
  String totalDays(int d) => get('Total ($d d)', 'Total ($d d)');
  String get peeOnly => get('Pee only', 'Só xixi');
  String get diaperChangesPerDay => get('Diaper Changes per Day', 'Trocas de Fralda por Dia');
  String changesCount(int count) => get('$count changes', '$count trocas');
  String get peeVsPoopBreakdown => get('Pee vs Poop Breakdown', 'Detalhamento Xixi vs Cocô');
  String peePercent(int pct) => get('$pct% Pee', '$pct% Xixi');
  String bothPercent(int pct) => get('$pct% Both', '$pct% Ambos');
  String poopPercent(int pct) => get('$pct% Poop', '$pct% Cocô');
  String peeOnlyLabel(int count) => get('Pee only ($count)', 'Só xixi ($count)');
  String bothLabel(int count) => get('Both ($count)', 'Ambos ($count)');
  String poopOnlyLabel(int count) => get('Poop only ($count)', 'Só cocô ($count)');
  String get stoolTexture => get('Stool Texture', 'Textura das Fezes');
  String recommendedSleepFor(int months, double h) => get('Recommended sleep for ${months}mo: ${h}h', 'Sono recomendado para $months meses: ${h}h');
  String confidence(int pct) => get('$pct% confidence', '$pct% de confiança');

  // ── Paywall Features ──
  String get featureAdvancedInsights => get('Advanced insights & analytics', 'Insights e análises avançados');
  String get featureUnlimitedHistory => get('Unlimited history', 'Histórico ilimitado');
  String get featureSmartPredictions => get('Smart predictions', 'Previsões inteligentes');
  String get featureMultipleBabies => get('Multiple babies', 'Múltiplos bebês');
  String get featureCloudBackup => get('Cloud backup', 'Backup na nuvem');
  String get close => get('Close', 'Fechar');
  String get noPurchasesFoundSimple => get('No purchases found', 'Nenhuma compra encontrada');

  // ── Pro Gate ──
  String get unlockInsights => get('Unlock Insights', 'Desbloquear Insights');
  String get unlockInsightsDesc => get(
    'Upgrade to Pro to see detailed analytics\nand predictions for your baby',
    'Torne-se Pro para ver análises detalhadas\ne previsões do seu bebê',
  );
  String get unlockNotifications => get('Unlock Smart Notifications', 'Desbloquear Notificações Inteligentes');
  String get unlockNotificationsDesc => get(
    'Upgrade to Pro to configure smart\nnotification reminders',
    'Torne-se Pro para configurar lembretes\nde notificação inteligentes',
  );

  // ── Event Types ──
  String get eventTypeSleep => get('Sleep', 'Sono');
  String get eventTypeFeed => get('Feed', 'Mamada');
  String get eventTypePee => get('Pee', 'Xixi');
  String get eventTypePoop => get('Poop', 'Cocô');
  String get eventTypePeeAndPoop => get('Pee & Poop', 'Xixi & Cocô');

  // ── Feed Sheet ──
  String get startTime => get('Start', 'Início');
  String get endTime => get('End', 'Fim');

  // ── Bug Report ──
  String get reportBug => get('Report a Bug', 'Reportar um Bug');
  String get reportBugDesc => get('Describe the issue you found', 'Descreva o problema que encontrou');
  String get bugTitle => get('Title', 'Título');
  String get bugTitleHint => get('Brief summary of the issue', 'Resumo breve do problema');
  String get bugDescription => get('Description', 'Descrição');
  String get bugDescriptionHint => get('What happened? What did you expect?', 'O que aconteceu? O que você esperava?');
  String get bugEmail => get('Email (optional)', 'Email (opcional)');
  String get bugEmailHint => get('In case we need to contact you', 'Caso precisemos entrar em contato');
  String get bugSubmit => get('Submit Report', 'Enviar Relatório');
  String get bugSubmitting => get('Submitting...', 'Enviando...');
  String get bugSuccess => get('Bug report sent! Thank you.', 'Relatório enviado! Obrigado.');
  String get bugError => get('Failed to send report. Try again.', 'Falha ao enviar relatório. Tente novamente.');
  String get bugTitleRequired => get('Please enter a title', 'Por favor, digite um título');
  String get bugDescriptionRequired => get('Please describe the issue', 'Por favor, descreva o problema');
  String get reportBugHome => get('Found a bug? Tell us', 'Encontrou um bug? Conte-nos');

  // ── Review ──
  String get rateApp => get('Rate NestRoutine', 'Avaliar NestRoutine');
}
