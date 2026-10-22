# Bhakti App – Landing Page & GitHub Pages Deployment Guide

This directory (`/docs`) hosts the production-ready landing page and the official Google Play privacy policy for **Bhakti – Devotional Music & Hindu Panchanga**, authored by **Srivatsa Malali**.

---

## 📁 Directory Architecture

```text
docs/
├── home.html                # 🌟 Primary Landing Page (Bhakti – Devotional Music & Hindu Panchanga)
├── landing.html             # Direct alias of home.html for flexible navigation
├── index.html               # 🛡️ Official Privacy Policy (Google Play approved URL: /bhakti/)
├── privacy-policy.html      # Privacy Policy alias (/bhakti/privacy-policy.html)
├── ads_rewards_future_ref...# Internal project documentation
├── assets/
│   └── images/
│       ├── app_icon.png     # High-resolution application icon
│       ├── bhakti_logo.png  # Sacred Bhakti brand logo
│       ├── logo.png         # Brand asset
│       ├── developer_avatar.png # Portrait of developer Srivatsa Malali
│       └── favicon.png      # Web browser favicon
└── README.md                # This deployment and preview guide
```

---

## 🌐 Live URLs on GitHub Pages

* **Official Privacy Policy**:  
  `https://srivatsamalali.github.io/bhakti/`  
  *(Preserved 100% intact to maintain compliance with Google Play submission #31)*
* **Bhakti App Landing Page**:  
  `https://srivatsamalali.github.io/bhakti/home.html`  
  *(Also accessible via `/bhakti/landing.html`)*
* **Developer Portfolio**:  
  `https://srivatsamalali.github.io/My-profile/`
* **Developer LinkedIn**:  
  `https://www.linkedin.com/in/srivatsamalali`

---

## 🖥️ Local Preview Instructions

You can preview the landing page and privacy policy locally using any static web server:

### Option 1: Python 3 (Built-in on macOS)
```bash
# Navigate to the docs folder
cd "/Users/srivatsamalali/projects/devotional app/docs"

# Start local server on port 8000
python3 -m http.server 8000
```
Open your browser and visit:
* Landing Page: `http://localhost:8000/home.html`
* Privacy Policy: `http://localhost:8000/`

### Option 2: Node / npx serve
```bash
npx -y serve docs
```

---

## 🚀 GitHub Pages Deployment Workflow

Your repository already has an automated GitHub Actions deployment configured in `.github/workflows/deploy-pages.yml`:

```yaml
on:
  push:
    branches:
      - main
    paths:
      - 'docs/**'
```

### Steps to Deploy:
1. Commit the newly created landing page files and assets:
   ```bash
   git add docs/
   git commit -m "feat(docs): add production landing page for Bhakti app and assets"
   git push origin main
   ```
2. GitHub Actions will automatically run the **Deploy Privacy Policy to GitHub Pages** workflow.
3. Within 1–2 minutes, your landing page will be live at `https://srivatsamalali.github.io/bhakti/home.html`.

---

## 📋 Missing Assets & Action Items for Final Launch

| Item | Current Status | Action Required Once Live |
|---|---|---|
| **Google Play Public URL** | Approved (Submission 31), Rollout in progress | Once Google completes search indexing, update the download button in `docs/home.html` with your live store link (`https://play.google.com/store/apps/details?id=com.bhakti.bhakti`). |
| **Physical App Screenshots** | High-fidelity UI cards rendered via CSS/HTML | For marketing app store showcases, you can place 2–3 PNG screenshots of the app running on your iPhone or Android device inside `docs/assets/images/screenshots/` and link them in the App Preview section. |
| **Canonical URL** | Commented in `<head>` | Once custom domain or preferred URL routing is finalized, enable `<link rel="canonical" href="...">`. |

---

## 🕉️ Sanskrit Inscription
॥ लोकाः समस्ताः सुखಿನೋ ಭವಂತು ॥
