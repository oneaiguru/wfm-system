import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter as Router } from 'react-router-dom';
import WorkflowTabs from './ui/src/pages/WorkflowTabs';
import './ui/src/index.css';

const root = ReactDOM.createRoot(
  document.getElementById('root') as HTMLElement
);

root.render(
  <React.StrictMode>
    <Router>
      <div className="App">
        <WorkflowTabs />
      </div>
    </Router>
  </React.StrictMode>
);