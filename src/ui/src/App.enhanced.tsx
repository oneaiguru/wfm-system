import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import EnhancedWorkflowTabs from './pages/EnhancedWorkflowTabs';
import './index.css';

function App() {
  return (
    <Router>
      <div className="App">
        <Routes>
          <Route path="/" element={<EnhancedWorkflowTabs />} />
          <Route path="/workflow" element={<EnhancedWorkflowTabs />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;