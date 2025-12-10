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
