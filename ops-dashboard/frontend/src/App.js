import React, { useState, useEffect } from 'react';
import { Line, Bar } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js';

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  Title,
  Tooltip,
  Legend
);

function App() {
  const [data, setData] = useState(null);

  useEffect(() => {
    // Load sample data
    fetch('/data/sample_aggregated.json')
      .then(response => response.json())
      .then(data => setData(data));
  }, []);

  if (!data) return <div>Loading...</div>;

  const dauData = {
    labels: data.dau.map(d => d.date),
    datasets: [{
      label: 'Daily Active Users',
      data: data.dau.map(d => d.value),
      borderColor: 'rgb(75, 192, 192)',
      tension: 0.1
    }]
  };

  const sessionLengthData = {
    labels: data.session_length.map(d => d.date),
    datasets: [{
      label: 'Average Session Length (minutes)',
      data: data.session_length.map(d => d.value),
      borderColor: 'rgb(255, 99, 132)',
      tension: 0.1
    }]
  };

  const favoriteConversionData = {
    labels: data.favorite_conversion.map(d => d.date),
    datasets: [{
      label: 'Favorite Conversion Rate (%)',
      data: data.favorite_conversion.map(d => d.value),
      backgroundColor: 'rgba(54, 162, 235, 0.2)',
      borderColor: 'rgba(54, 162, 235, 1)',
      borderWidth: 1
    }]
  };

  const listingEngagementData = {
    labels: data.listing_engagement.map(d => d.date),
    datasets: [{
      label: 'Listing Engagement Score',
      data: data.listing_engagement.map(d => d.value),
      backgroundColor: 'rgba(255, 206, 86, 0.2)',
      borderColor: 'rgba(255, 206, 86, 1)',
      borderWidth: 1
    }]
  };

  const retentionData = {
    labels: data.retention_proxies.map(d => d.date),
    datasets: [{
      label: 'Retention Proxy',
      data: data.retention_proxies.map(d => d.value),
      borderColor: 'rgb(153, 102, 255)',
      tension: 0.1
    }]
  };

  return (
    <div style={{ padding: '20px' }}>
      <h1>Product Telemetry Dashboard</h1>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
        <div>
          <h2>Daily Active Users</h2>
          <Line data={dauData} />
        </div>
        <div>
          <h2>Average Session Length</h2>
          <Line data={sessionLengthData} />
        </div>
        <div>
          <h2>Favorite Conversion Rate</h2>
          <Bar data={favoriteConversionData} />
        </div>
        <div>
          <h2>Listing Engagement</h2>
          <Bar data={listingEngagementData} />
        </div>
        <div style={{ gridColumn: 'span 2' }}>
          <h2>Retention Proxies</h2>
          <Line data={retentionData} />
        </div>
      </div>
    </div>
  );
}

export default App;