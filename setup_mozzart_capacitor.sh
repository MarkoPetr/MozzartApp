#!/data/data/com.termux/files/usr/bin/bash

echo "=== CLEAN START ==="
rm -rf MozzartApp
mkdir MozzartApp
cd MozzartApp

echo "=== Installing Node, Git, Ionic ==="
pkg update -y
pkg install -y nodejs git

npm install -g ionic --force

echo "=== Creating Ionic Angular (Tabs) project ==="
ionic start MozzartApp tabs --type=angular --capacitor

cd MozzartApp

echo "=== Installing dependencies ==="
npm install axios papaparse
npm install --save-dev @types/papaparse

echo "=== Adding typings for papaparse ==="
echo "declare module 'papaparse';" > src/typings.d.ts

echo "=== Updating Tab1 page (standalone component) ==="
cat > src/app/tab1/tab1.page.ts << 'TS_EOF'
import { Component } from '@angular/core';
import { IonicModule } from '@ionic/angular';
import axios from 'axios';

@Component({
  selector: 'app-tab1',
  standalone: true,
  imports: [IonicModule],
  templateUrl: 'tab1.page.html',
  styleUrls: ['tab1.page.scss']
})
export class Tab1Page {
  matches: any[] = [];
  loading = false;

  async loadResults() {
    this.loading = true;
    this.matches = [];

    try {
      const url = 'https://www.mozzartbet.com/sr/rezultati?events=finished';
      const r = await axios.get(url);

      const parser = new DOMParser();
      const doc = parser.parseFromString(r.data, 'text/html');

      const rows = Array.from(doc.querySelectorAll('div.scorerow, div.event-row'));

      rows.forEach(el => {
        const team = el.querySelector('span.event-name')?.textContent?.trim() ?? '';
        const result = el.querySelector('span.result')?.textContent?.trim() ?? '';
        const time = el.querySelector('span.date')?.textContent?.trim() ?? '';

        if (team && result && time) {
          this.matches.push({ team, result, time });
        }
      });

    } catch (err) {
      console.error('GRESKA:', err);
    }

    this.loading = false;
  }
}
TS_EOF

echo "=== Updating Tab1 HTML ==="
cat > src/app/tab1/tab1.page.html << 'HTML_EOF'
<ion-header>
  <ion-toolbar color="primary">
    <ion-title>Mozzart Rezultati</ion-title>
  </ion-toolbar>
</ion-header>

<ion-content class="ion-padding">
  <ion-button expand="block" (click)="loadResults()">Učitaj završene mečeve</ion-button>

  <ion-spinner *ngIf="loading"></ion-spinner>

  <ion-grid *ngIf="matches.length > 0">
    <ion-row>
      <ion-col><b>Timovi</b></ion-col>
      <ion-col><b>Rezultat</b></ion-col>
      <ion-col><b>Vreme</b></ion-col>
    </ion-row>

    <ion-row *ngFor="let m of matches">
      <ion-col>{{ m.team }}</ion-col>
      <ion-col>{{ m.result }}</ion-col>
      <ion-col>{{ m.time }}</ion-col>
    </ion-row>
  </ion-grid>
</ion-content>
HTML_EOF

echo "=== Removing all ngModules for standalone ==="
find src/app -name "*.module.ts" -type f -delete

echo "=== Setting Capacitor Android ==="
ionic capacitor add android

echo "=== Set Android min/max SDK ==="
npx cap set android.minSdkVersion 22
npx cap set android.targetSdkVersion 34

echo "=== Build web assets ==="
npm run build
npx cap copy

echo "=== Git setup ==="
git init
git add .
git commit -m "Ionic + Capacitor MozzartApp (Tabs + Standalone + Android Ready)"
git branch -M main
git remote add origin https://MarkoPetr@github.com/MarkoPetr/MozzartApp.git
git push -u origin main --force

echo "=== DONE! Capacitor Android build should pass in Appflow ==="
