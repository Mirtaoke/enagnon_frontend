# MultiShop Management - Application de Gestion de Boutiques

Une application complète pour gérer plusieurs boutiques avec des employés, des transactions de vente/approvisionnement, une gestion dynamique de caisse, des rapports automatiques et un système de discussion par boutique.

## 🚀 Architecture

### Backend (Laravel 13)
- **Localisation**: `/multishop_api/`
- **API REST** pour tous les endpoints
- **Modèles**: Shop, Employee, StockMovement, Report, Chat, Message, User
- **Authentification par token API**

### Frontend (Flutter)
- **Localisation**: `/multishop/`
- **Architecture**: Clean Architecture avec Business Logic (Cubits)
- **État**: flutter_bloc pour la gestion d'état
- **Design**: Thème gradient coloré et moderne avec icons Material

## 📋 Estructura du Frontend

```
lib/
├── business_logic/cubits/
│   ├── auth/
│   ├── shop/
│   ├── transaction/
│   ├── report/
│   └── chat/
├── config/
├── core/
│   ├── constants/
│   ├── network/
│   ├── storage/
│   ├── theme/
│   └── utils/
├── data/
│   ├── models/
│   ├── providers/
│   └── repositories/
├── presentation/
│   ├── pages/
│   └── widgets/
└── main.dart
```

## 🛠️ Installation et Démarrage

### 1. Backend Laravel

```bash
# Accéder au dossier backend
cd /home/mirta/Documents/Projet_exp/multishop_api

# Installer les dépendances
composer install

# Exécuter les migrations et seeds
php artisan migrate:fresh --seed

# Démarrer le serveur
php artisan serve --host=0.0.0.0 --port=8000
```

**Données de test:**
- Email: `admin@multishop.test`
- Mot de passe: `password`

### 2. Frontend Flutter

```bash
# Accéder au dossier frontend
cd /home/mirta/Documents/Projet_exp/multishop

# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run
```

## 📡 API Endpoints

### Authentification
- `POST /api/auth/login` - Se connecter
- `GET /api/auth/me` - Récupérer l'utilisateur courant

### Boutiques
- `GET /api/summary` - Récapitulatif global
- `GET /api/shops` - Lister toutes les boutiques
- `GET /api/shops/{id}` - Détails d'une boutique
- `GET /api/shops/{id}/employees` - Employés d'une boutique
- `GET /api/shops/{id}/cash` - État de la caisse
- `GET /api/shops/{id}/reports` - Rapports de la boutique

### Transactions
- `POST /api/shops/{id}/transactions` - Enregistrer une vente/approvisionnement

### Forums/Chat
- `GET /api/shops/{id}/chats` - Lister les chats par boutique
- `GET /api/chats/{id}/messages` - Messages d'un chat
- `POST /api/chats/{id}/messages` - Envoyer un message

## 🎨 Design et Couleurs

**Palette de couleurs:**
- Primaire: `#5B4BD8` (Violet)
- Secondaire: `#8C6FFD` (Violet clair)
- Accent: `#FFB23D` (Orange)
- Background: `#F6F0FF` (Violet très clair)
- Danger: `#EF476F` (Rouge)

**Éléments de design:**
- Gradients colorés pour les cartes
- Icônes Material Design
- Coins arrondis (BorderRadius 12-20px)
- Ombres subtiles avec BoxShadow

## 📱 Fonctionnalités Principales

### Pour l'Admin
- ✅ Tableau de bord avec résumé global
- ✅ Vue d'ensemble des boutiques
- ✅ Nombre d'employés par boutique
- ✅ Caisse globale
- ✅ Consultation des rapports quotidiens
- ✅ Forums de discussion par boutique
- ✅ Messages privés avec employés

### Pour les Boutiques
- ✅ Page détail avec caisse en temps réel
- ✅ Enregistrement des ventes
- ✅ Enregistrement des approvisionnements
- ✅ Liste des employés
- ✅ Rapports quotidiens automatiques
- ✅ Forum de discussion employé-admin

### Pour les Employés
- ✅ Accès au chat de la boutique
- ✅ Communication avec l'admin
- ✅ Vue des transactions

## 🔐 Sécurité

- Authentification par token API
- Tokens stockés localement via SharedPreferences
- Validations côté frontend et backend
- Endpoints API protégés

## 📊 Gestion des Données

### Rapports
- Générés automatiquement chaque jour
- Contiennent: Entrées (ventes), Sorties (approvisionnement), Bilan
- Affichés dans le forum de chaque boutique

### Caisse
- Calculée dynamiquement: Total ventes - Total approvisionnements
- Mise à jour en temps réel après chaque transaction
- Affichée globalement et par boutique

### Chats/Forums
- Un forum par boutique
- Créé automatiquement lors du premier accès
- Messages avec sender et receiver
- Historique persistant

## 🔧 Configurations Importantes

**API Base URL**: `http://10.0.2.2:8000/api` (pour emulateur Android)
- Modifier dans `lib/config/app_config.dart` si nécessaire

**Langue**: Français (intl avec locale `fr_FR`)

## 📦 Dépendances Clés

### Backend
- Laravel 13
- Migrations & Seeding

### Frontend
- flutter_bloc: Gestion d'état
- http: Requêtes API
- shared_preferences: Stockage local
- intl: Internationalisation
- equatable: Comparaison d'objets

## 🎯 Prochaines Étapes (Optionnel)

- [ ] Photos de profil pour employés
- [ ] Notifications en temps réel
- [ ] Export des rapports en PDF
- [ ] Statistiques avancées
- [ ] Mode sombre
- [ ] Support multilingue (EN, ES, PT)

---

**Développé le 10 août 2026**
