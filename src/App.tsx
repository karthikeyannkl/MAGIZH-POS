import { useState } from 'react'
import {
  LayoutDashboard, ReceiptText, Package, Users, MoreHorizontal,
  Search, Bell, Plus, ArrowUpRight, Wallet, Banknote, Smartphone,
  AlertTriangle, ChevronRight, Menu
} from 'lucide-react'

type Tab = 'home' | 'billing' | 'products' | 'customers' | 'more'

export default function App() {
  const [tab, setTab] = useState<Tab>('home')
  const [language, setLanguage] = useState<'EN' | 'தமிழ்'>('EN')
  const [showInstallHint, setShowInstallHint] = useState(false)

  const labels = language === 'EN'
    ? { home: 'Home', billing: 'Billing', products: 'Products', customers: 'Customers', more: 'More', today: "Today's sales", bills: 'Total bills', cash: 'Cash collection', upi: 'UPI collection', quick: 'Quick actions', newBill: 'New bill', stock: 'Stock alerts', setup: 'Setup required' }
    : { home: 'முகப்பு', billing: 'பில்லிங்', products: 'பொருட்கள்', customers: 'வாடிக்கையாளர்கள்', more: 'மேலும்', today: 'இன்றைய விற்பனை', bills: 'மொத்த பில்கள்', cash: 'ரொக்க வசூல்', upi: 'UPI வசூல்', quick: 'விரைவு செயல்கள்', newBill: 'புதிய பில்', stock: 'ஸ்டாக் எச்சரிக்கை', setup: 'அமைப்பு தேவை' }

  const nav = [
    { id: 'home' as const, label: labels.home, icon: LayoutDashboard },
    { id: 'billing' as const, label: labels.billing, icon: ReceiptText },
    { id: 'products' as const, label: labels.products, icon: Package },
    { id: 'customers' as const, label: labels.customers, icon: Users },
    { id: 'more' as const, label: labels.more, icon: MoreHorizontal }
  ]

  return (
    <div className="app-shell">
      <header className="topbar">
        <div className="brand-lockup">
          <div className="brand-mark">M</div>
          <div><div className="brand-name">MAGIZH <span>POS</span></div><div className="brand-sub">BUSINESS MANAGEMENT</div></div>
        </div>
        <div className="top-actions">
          <button className="icon-button" aria-label="Notifications"><Bell size={19}/></button>
          <button className="language-button" onClick={() => setLanguage(language === 'EN' ? 'தமிழ்' : 'EN')}>{language}</button>
        </div>
      </header>

      <main className="content">
        {tab === 'home' && <>
          <section className="welcome-row">
            <div><p className="eyebrow">MAGIZH CAFE</p><h1>Business overview</h1><p className="muted">Branch selection and live data will appear after setup.</p></div>
            <button className="branch-button"><Menu size={16}/> Branch 1 <ChevronRight size={15}/></button>
          </section>

          <section className="hero-card">
            <div className="hero-top"><span className="hero-label">{labels.today}</span><span className="live-dot">● Setup preview</span></div>
            <div className="hero-amount">—</div>
            <div className="hero-foot"><span>Sales data will load from your secure database.</span><ArrowUpRight size={18}/></div>
          </section>

          <section className="metric-grid">
            <Metric icon={<ReceiptText/>} label={labels.bills} value="—" tone="green"/>
            <Metric icon={<Banknote/>} label={labels.cash} value="—" tone="orange"/>
            <Metric icon={<Smartphone/>} label={labels.upi} value="—" tone="green"/>
            <Metric icon={<Wallet/>} label="Discounts" value="—" tone="orange"/>
          </section>

          <section className="section-block">
            <div className="section-heading"><h2>{labels.quick}</h2><span className="muted">Daily operations</span></div>
            <div className="quick-grid">
              <button className="quick-action primary" onClick={() => setTab('billing')}><span className="quick-icon"><Plus/></span><span>{labels.newBill}</span></button>
              <button className="quick-action" onClick={() => setTab('products')}><span className="quick-icon"><Package/></span><span>Manage products</span></button>
              <button className="quick-action" onClick={() => setTab('customers')}><span className="quick-icon"><Users/></span><span>Customers</span></button>
              <button className="quick-action" onClick={() => setTab('more')}><span className="quick-icon"><Search/></span><span>Reports & more</span></button>
            </div>
          </section>

          <section className="notice-card">
            <div className="notice-icon"><AlertTriangle size={19}/></div>
            <div><strong>{labels.setup}</strong><p>Connect Supabase and configure business, branches, roles and permissions before processing real bills.</p></div>
          </section>
        </>}

        {tab !== 'home' && <section className="module-placeholder">
          <div className="module-icon">{nav.find(n => n.id === tab)?.icon && (() => { const Icon = nav.find(n => n.id === tab)!.icon; return <Icon size={27}/> })()}</div>
          <p className="eyebrow">MAGIZH POS MODULE</p>
          <h1>{nav.find(n => n.id === tab)?.label}</h1>
          <p className="muted">This module is planned in the development roadmap. Real billing and business data will be enabled only after its backend and security tests pass.</p>
          {tab === 'billing' && <button className="primary-button" onClick={() => setShowInstallHint(true)}>View setup requirements</button>}
          {showInstallHint && <p className="inline-note">Billing will be activated after secure payment, invoice and stock workflows are implemented.</p>}
        </section>}
      </main>

      <nav className="bottom-nav" aria-label="Main navigation">
        {nav.map(item => {
          const Icon = item.icon
          return <button key={item.id} className={`nav-item ${tab === item.id ? 'active' : ''}`} onClick={() => { setTab(item.id); setShowInstallHint(false) }}>
            <Icon size={21} strokeWidth={tab === item.id ? 2.4 : 1.8}/><span>{item.label}</span>
          </button>
        })}
      </nav>
      <div className="safe-bottom"/>
    </div>
  )
}

function Metric({ icon, label, value, tone }: { icon: React.ReactNode, label: string, value: string, tone: 'green' | 'orange' }) {
  return <div className="metric-card"><div className={`metric-icon ${tone}`}>{icon}</div><p>{label}</p><strong>{value}</strong></div>
}