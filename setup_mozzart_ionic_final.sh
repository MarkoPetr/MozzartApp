#!/data/data/com.termux/files/usr/bin/bash

echo "=== CLEAN START ==="
rm -rf MozzartApp
mkdir MozzartApp
cd MozzartApp

echo "=== Installing Node.js, Ionic, Cordova ==="
pkg update -y && pkg upgrade -y
pkg install -y nodejs git curl

npm install -g ionic cordova --force

echo "=== Creating Ionic + Cordova project ==="
ionic start MozzartApp blank --type=angular --capacitor=false
cd MozzartApp
ionic integrations enable cordova

echo "=== Adding Android platform ==="
ionic cordova platform add android

echo "=== Installing required packages ==="
npm install axios papaparse
npm install --save-dev @types/papaparse

echo "=== Creating typings.d.ts for papaparse ==="
echo "declare module 'papaparse';" > src/typings.d.ts

echo "=== Replacing src/app/home/home.page.html with modern UI ==="
cat > src/app/home/home.page.html << 'HTML_EOF'
<ion-header>
  <ion-toolbar color="primary">
    <ion-title>Mozzart Rezultati</ion-title>
  </ion-toolbar>
</ion-header>

<ion-content class="ion-padding">
  <ion-button expand="block" color="secondary" (click)="loadResults()">
    Učitaj završene mečeve
  </ion-button>
  <ion-spinner *ngIf="loading" name="crescent"></ion-spinner>
  <ion-grid *ngIf="matches.length>0">
    <ion-row>
      <ion-col><strong>Timovi</strong></ion-col>
      <ion-col><strong>Rezultat</strong></ion-col>
      <ion-col><strong>Vreme</strong></ion-col>
    </ion-row>
    <ion-row *ngFor="let m of matches">
      <ion-col>{{m.team}}</ion-col>
      <ion-col>{{m.result}}</ion-col>
      <ion-col>{{m.time}}</ion-col>
    </ion-row>
  </ion-grid>
</ion-content>
HTML_EOF

echo "=== Replacing src/app/home/home.page.ts (NON-standalone) ==="
cat > src/app/home/home.page.ts << 'TS_EOF'
import { Component } from '@angular/core';
import axios from 'axios';
import * as Papa from 'papaparse';

@Component({
  selector: 'app-home',
  templateUrl: 'home.page.html',
  styleUrls: ['home.page.scss']
})
export class HomePage {
  matches: any[] = [];
  loading: boolean = false;

  constructor() {}

  async loadResults() {
    this.loading = true;
    this.matches = [];

    try {
      const url = 'https://www.mozzartbet.com/sr/rezultati?events=finished';
      const res = await axios.get(url);
      const parser = new DOMParser();
      const doc = parser.parseFromString(res.data, 'text/html');

      const rows = Array.from(doc.querySelectorAll('div.scorerow, div.event-row'));
      rows.forEach(r => {
        try {
          const team = r.querySelector('span.event-name')?.textContent?.trim() || '';
          const result = r.querySelector('span.result')?.textContent?.trim() || '';
          const time = r.querySelector('span.date')?.textContent?.trim() || '';
          if(team && result && time){
            this.matches.push({team, result, time});
          }
        } catch {}
      });
    } catch (e) {
      console.error('Error fetching results:', e);
    }

    this.loading = false;
  }
}
TS_EOF

echo "=== Replacing src/app/home/home.module.ts ==="
cat > src/app/home/home.module.ts << 'MODULE_EOF'
import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { IonicModule } from '@ionic/angular';
import { RouterModule } from '@angular/router';

import { HomePage } from './home.page';

@NgModule({
  imports: [
    CommonModule,
    FormsModule,
    IonicModule,
    RouterModule.forChild([{ path: '', component: HomePage }])
  ],
  declarations: [HomePage]
})
export class HomePageModule {}
MODULE_EOF

echo "=== Git setup and initial commit ==="
git init
git add .
git commit -m "Initial Ionic + Cordova MozzartApp ready for Appflow"
git branch -M main
git remote add origin https://MarkoPetr@github.com/MarkoPetr/MozzartApp.git
git push -u origin main --force

echo "=== DONE! Ionic Cordova MozzartApp final is ready for Appflow ==="
