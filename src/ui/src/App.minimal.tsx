import React from 'react';

function App() {
  // Simple test component to verify React is working
  console.log('App component loaded!');
  
  const handleClick = async () => {
    try {
      const response = await fetch('http://localhost:8000/api/v1/requests/vacation', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          employee_id: 2,
          request_type: 'vacation',
          start_date: '2025-08-20',
          end_date: '2025-08-25',
          description: 'Test from minimal UI'
        })
      });
      const data = await response.json();
      alert('Success! Request ID: ' + data.id);
      console.log('Response:', data);
    } catch (error) {
      alert('Error: ' + error);
      console.error('Error:', error);
    }
  };
  
  return (
    <div style={{ padding: '20px', fontFamily: 'sans-serif' }}>
      <h1>WFM Enterprise System - Minimal Test</h1>
      <p>✅ React is working!</p>
      <p>✅ UI Server is running</p>
      <p>✅ Ready to test vacation request</p>
      
      <div style={{ marginTop: '20px', padding: '15px', backgroundColor: '#f0f0f0', borderRadius: '5px' }}>
        <h2>Vacation Request Test</h2>
        <p>Click the button to submit a test vacation request:</p>
        <pre style={{ fontSize: '12px', backgroundColor: '#fff', padding: '10px', borderRadius: '3px' }}>
{JSON.stringify({
  employee_id: 2,
  request_type: 'vacation',
  start_date: '2025-08-20',
  end_date: '2025-08-25',
  description: 'Test from minimal UI'
}, null, 2)}
        </pre>
        <button 
          onClick={handleClick}
          style={{ 
            marginTop: '10px',
            padding: '10px 20px',
            backgroundColor: '#4CAF50',
            color: 'white',
            border: 'none',
            borderRadius: '4px',
            cursor: 'pointer',
            fontSize: '16px'
          }}
        >
          Submit Vacation Request
        </button>
      </div>
    </div>
  );
}

export default App;