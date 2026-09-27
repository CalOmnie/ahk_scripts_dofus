# Scripts AutoHotkey pour Dofus

## ⚠️ Avertissement

Plusieurs de ces scripts automatisent des actions dans le jeu (lecture des fenêtres ouvertes, envoi de commandes, répétition de clics, lecture de texte à l'écran) sur un ou plusieurs comptes à la fois. Les CGU d'Ankama interdisent l'usage de bots ou de toute automatisation remplaçant une action humaine ou donnant un avantage compétitif. Les raccourcis marqués ⚠️ dans les sections ci-dessous effectuent **plusieurs actions automatiques d'affilée, ou la même action sur plusieurs fenêtres à la fois**, et sont donc les plus susceptibles d'être considérés comme de l'automatisation au sens des CGU. Utilisez-les en connaissance de cause et à vos propres risques.

## Prérequis
- [AutoHotkey v2](https://www.autohotkey.com/)
- [Bibliothèque OCR](https://github.com/Descolada/OCR) (à installer dans le dossier `Autohotkey/Lib`, nécessaire uniquement pour `recipe_price.ahk`). Pour plus d'information regardez sur la documentation officielle [ici](https://www.autohotkey.com/docs/v2/Scripts.htm#lib)

## Installation
- Clonez le dépôt, téléchargez les scripts individuellement, ou copiez-collez directement les fonctions dont vous avez besoin dans un fichier `.ahk`
- Double-cliquez sur un script pour le lancer et l'essayer

### Lancer un script au démarrage
- Faites un clic droit sur le script voulu, puis "Créer un raccourci"
- "Coupez" le raccourci (`Ctrl+X` ou clic droit -> Couper)
- Appuyez sur `Win+R`
- Tapez `shell:startup`
- Collez le raccourci dans le dossier

## Organisation des scripts

Chaque script suit la même structure :
- `;; CONFIGURATION` : les raccourcis clavier et les réglages modifiables, en haut du fichier — c'est ici qu'il faut changer une touche ou ajouter une entrée (lieu nommé, personnage, etc.)
- `;; IMPLEMENTATION` : la logique du script
- `;; UTILITIES` : fonctions utilitaires propres au script

Tous les raccourcis ne fonctionnent que lorsqu'une fenêtre Dofus est au premier plan. `utils.ahk` (voir plus bas) regroupe les fonctions partagées par les autres scripts, notamment cette vérification.

---

## `grouping.ahk` — invitation de groupe

| Raccourci par défaut | Action |
|---|---|
| `Ctrl+G` | Invite dans le groupe tous les autres personnages Dofus actuellement ouverts |

Le script lit le titre de chaque fenêtre Dofus ouverte (format `NOM - CLASSE - VERSION - TYPE`), construit une commande `/invite Nom1; /invite Nom2; ...` en excluant le personnage actif, la copie dans le presse-papiers puis l'envoie dans le chat de la fenêtre active.

---

## `travel.ahk` — déplacement via zaap

| Raccourci par défaut | Action |
|---|---|
| `Ctrl+Y` | Demande des coordonnées (ou le nom d'un lieu enregistré), calcule le zaap le plus proche et envoie `/zaap X Y; /travel x y` dans la fenêtre active |
| `Ctrl+Maj+Y` ⚠️ | Identique à `Ctrl+Y`, mais envoie la commande dans **toutes** les fenêtres Dofus actives |
| `Ctrl+Maj+C` ⚠️ | Envoie le contenu actuel du presse-papiers dans **toutes** les fenêtres Dofus actives, sans rien demander |
| `Ctrl+Maj+V` | Envoie le contenu actuel du presse-papiers uniquement dans la fenêtre active |

Des lieux nommés peuvent être définis dans `namedLocations` (section CONFIGURATION), avec des coordonnées et, en option, un raccourci dédié qui y téléporte directement sans passer par la fenêtre de saisie. La liste des zaaps utilisée pour trouver le plus proche vient de `data/zaaps.yaml`.

⚠️ **Les raccourcis qui diffusent une commande sur toutes les fenêtres ouvertes appliquent la même action à plusieurs comptes en une seule pression de touche.**

---

## `multi_account.ahk` — gestion multi-compte

| Raccourci par défaut | Action |
|---|---|
| `F5` | Passe à la fenêtre Dofus suivante |
| `F6` | Passe à la fenêtre suivante puis clique à la position actuelle de la souris |
| `F7` ⚠️ | Démarre/arrête l'enregistrement des clics sur la fenêtre active ; à l'arrêt, **rejoue automatiquement la séquence de clics enregistrée sur toutes les autres fenêtres Dofus ouvertes** |
| Raccourcis définis dans `characterShortcuts` (ex. `F1`, `F2`) | Bascule directement vers la fenêtre du personnage correspondant si elle est ouverte, sans rien faire sinon |

⚠️ **`F7` automatise une séquence de clics identique sur l'ensemble de vos comptes sans intervention manuelle entre chacun — c'est l'usage le plus proche d'un bot parmi ces scripts.**

---

## `recipe_price.ahk` — calcul de prix de recette

| Raccourci par défaut | Action |
|---|---|
| `Ctrl+P` ⚠️ | Calcule automatiquement le prix total d'une recette en déplaçant la souris et en lisant par OCR le prix moyen de chaque ingrédient, l'un après l'autre |
| `Ctrl+Maj+P` | Identique à `Ctrl+P`, mais affiche les étapes de détection (mode debug) |
| `Ctrl+U` | Ajoute un prix détecté à un cumul manuel ; repasser sans détection affiche le total et le réinitialise |
| `Ctrl+Maj+U` | Détecte un seul prix, en mode debug |

⚠️ **`Ctrl+P` déplace la souris et enchaîne plusieurs lectures automatiques sans intervention manuelle entre chaque ingrédient.**
