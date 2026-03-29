import { Component, OnInit, inject } from '@angular/core';
import { DashboardComponent } from './dashboard/dashboard.component';
import { LoggerService } from '../core/logger.service';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [DashboardComponent],
  template: `
    <app-dashboard />
  `,
  styles: [`
    :host {
      display: block;
      height: 100vh;
      width: 100%;
      overflow: hidden;
      background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
    }
  `]
})
export class AppComponent implements OnInit {
  private readonly logger = inject(LoggerService);

  ngOnInit(): void {
    this.logger.info('DuckDB Dashboard Application Initialized');
  }
}
