#!/data/data/com.termux/files/usr/bin/bash

echo "=== CLEAN START ==="
rm -rf MozzartApp
mkdir MozzartApp
cd MozzartApp

echo "=== Installing Node.js, Ionic, Cordova ==="
pkg update -y && pkg upgrade -y
pkg install -y nodejs git curl
npm install -g ionic cordova --force

echo "=== Creating Ionic + Cordova project (tabs) ==="
ionic start MozzartApp tabs --type=angular --capacitor=false
cd MozzartApp
ionic integrations enable cordova

echo "=== Fixing standalone routing for Tab1 ==="
cat > src/app/tabs/tabs-routing.module.ts << 'ROUTING_EOF'
import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';

const routes: Routes = [
  {
    path: 'tabs',
    children: [
      {
        path: 'tab1',
        loadComponent: () => import('../tab1/tab1.page').then(m => m.Tab1Page)
      },
      {
        path: 'tab2',
        loadChildren: () => import('../tab2/tab2.module').then(m => m.Tab2PageModule)
      },
      {
        path: 'tab3',
        loadChildren: () => import('../tab3/tab3.module').then(m => m.Tab3PageModule)
      },
      {
        path: '',
        redirectTo: '/tabs/tab1',
        pathMatch: 'full'
      }
    ]
  },
  {
    path: '',
    redirectTo: '/tabs/tab1',
    pathMatch: 'full'
  }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class TabsPageRoutingModule {}
ROUTING_EOF

echo "=== Installing packages ==="
npm install axios papaparse
npm install --save-dev @types/papaparse

echo "declare module 'papaparse';" > src/typings.d.ts

echo "=== Replacing tab1.page.html ==="
cat > src/app/tab1/tab1.page.html << 'HTML_EOF'
<ion-header>
  <ion-toolbar color="primary">
    <ion-title>Mozzart Rezultati</ion-title>
  </ion-toolbar>
</ion-header>

<ion-content class="ion-padding">
  <ion-button expand="block" (click)="loadResults()">Učitaj završene mečeve</ion-button>
  <ion-spinner *ngIf="loading"></ion-spinner>

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

echo "=== Replacing tab1.page.ts ==="
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
      const res = await axios.get(url);

      const parser = new DOMParser();
      const doc = parser.parseFromString(res.data, 'text/html');

      const rows = Array.from(doc.querySelectorAll('div.scorerow, div.event-row'));
      rows.forEach(r => {
        const team = r.querySelector('span.event-name')?.textContent?.trim() || '';
        const result = r.querySelector('span.result')?.textContent?.trim() || '';
        const time = r.querySelector('span.date')?.textContent?.trim() || '';

        if (team && result && time) {
          this.matches.push({ team, result, time });
        }
      });
    } catch (e) {
      console.error(e);
    }

    this.loading = false;
  }
}
TS_EOF

echo "=== Removing old module ==="
rm -f src/app/tab1/tab1.module.ts

echo "=== Git setup ==="
git init
git add .
git commit -m "Standalone working MozzartApp (routing fixed)"
git branch -M main
git remote add origin https://MarkoPetr@github.com/MarkoPetr/MozzartApp.git
git push -u origin main --force

echo "=== SCRIPT COMPLETE ==="
