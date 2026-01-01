import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { Onboarding } from './pages/Onboarding';
import { Login } from './pages/Login';
import { Dashboard } from './pages/Dashboard';
// Collection Flow
import { SelectLocation } from './pages/Collect/SelectLocation';
import { ClientList } from './pages/Collect/ClientList';
import { RegisterPayment } from './pages/Collect/RegisterPayment';
// Create Credit Wizard
import { SearchClient } from './pages/CreateCredit/SearchClient';
import { ScanINE } from './pages/CreateCredit/ScanINE';
import { ConfirmData } from './pages/CreateCredit/ConfirmData';
import { PersonalInfo } from './pages/CreateCredit/PersonalInfo';
import { SelectCreditType } from './pages/CreateCredit/SelectCreditType';
import { CreditAmount } from './pages/CreateCredit/CreditAmount';
import { AddGuarantors } from './pages/CreateCredit/AddGuarantors';
import { RecordVideo } from './pages/CreateCredit/RecordVideo';
import { Summary } from './pages/CreateCredit/Summary';
// Client Management
import { ClientSearch } from './pages/Clients/Search';
import { ClientProfile } from './pages/Clients/Profile';
import { CreditDetail } from './pages/Clients/CreditDetail';
// Reports
import { Reports } from './pages/Reports';
export function App() {
  return <Router>
      <div className="min-h-screen bg-gray-50 font-sans text-text-primary antialiased">
        <Routes>
          <Route path="/" element={<Navigate to="/onboarding" replace />} />
          <Route path="/onboarding" element={<Onboarding />} />
          <Route path="/login" element={<Login />} />
          <Route path="/dashboard" element={<Dashboard />} />

          {/* Collection Routes */}
          <Route path="/collect" element={<SelectLocation />} />
          <Route path="/collect/:locationId" element={<ClientList />} />
          <Route path="/collect/payment/:clientId" element={<RegisterPayment />} />

          {/* Create Credit Wizard */}
          <Route path="/new" element={<Navigate to="/create-credit" replace />} />
          <Route path="/create-credit" element={<SearchClient />} />
          <Route path="/create-credit/scan-ine" element={<ScanINE />} />
          <Route path="/create-credit/confirm-data" element={<ConfirmData />} />
          <Route path="/create-credit/personal-info" element={<PersonalInfo />} />
          <Route path="/create-credit/select-type" element={<SelectCreditType />} />
          <Route path="/create-credit/amount" element={<CreditAmount />} />
          <Route path="/create-credit/guarantors" element={<AddGuarantors />} />
          <Route path="/create-credit/video" element={<RecordVideo />} />
          <Route path="/create-credit/summary" element={<Summary />} />

          {/* Client Management */}
          <Route path="/clients" element={<ClientSearch />} />
          <Route path="/clients/:clientId" element={<ClientProfile />} />
          <Route path="/clients/:clientId/credit/:creditId" element={<CreditDetail />} />

          {/* Reports */}
          <Route path="/reports" element={<Reports />} />
        </Routes>
      </div>
    </Router>;
}