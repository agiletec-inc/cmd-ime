
'use client';

import { useState } from 'react';
import Link from 'next/link';

interface KeyMapping {
  id: string;
  key: string;
  action: string;
  isEditing: boolean;
}

export default function Settings() {
  const [keyMappings, setKeyMappings] = useState<KeyMapping[]>([
    { id: '1', key: '左⌘キー単独押し', action: '英語入力', isEditing: false },
    { id: '2', key: '右⌘キー単独押し', action: '日本語入力', isEditing: false },
  ]);

  const [excludedApps, setExcludedApps] = useState([
    { id: '1', name: 'OBS Studio', enabled: false },
    { id: '2', name: 'ChatGPT', enabled: false },
    { id: '3', name: 'Visual Studio Code', enabled: false },
    { id: '4', name: 'Warp', enabled: false },
    { id: '5', name: 'システム設定', enabled: false },
    { id: '6', name: 'Chrome', enabled: false },
  ]);

  const [loginStartup, setLoginStartup] = useState(true);
  const [autoUpdate, setAutoUpdate] = useState(true);

  const editKeyMapping = (id: string) => {
    setKeyMappings(prev => prev.map(mapping => 
      mapping.id === id ? { ...mapping, isEditing: true } : mapping
    ));
  };

  const saveKeyMapping = (id: string, newKey: string, newAction: string) => {
    setKeyMappings(prev => prev.map(mapping => 
      mapping.id === id ? { ...mapping, key: newKey, action: newAction, isEditing: false } : mapping
    ));
  };

  const cancelEdit = (id: string) => {
    setKeyMappings(prev => prev.map(mapping => 
      mapping.id === id ? { ...mapping, isEditing: false } : mapping
    ));
  };

  const toggleApp = (id: string) => {
    setExcludedApps(prev => prev.map(app => 
      app.id === id ? { ...app, enabled: !app.enabled } : app
    ));
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Window Frame */}
      <div className="bg-white shadow-lg rounded-xl max-w-4xl mx-auto my-4" style={{height: 'calc(100vh - 2rem)'}}>
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200 bg-gray-50 rounded-t-xl">
          <div className="flex items-center space-x-3">
            <div className="w-3 h-3 bg-red-500 rounded-full"></div>
            <div className="w-3 h-3 bg-yellow-500 rounded-full"></div>
            <div className="w-3 h-3 bg-green-500 rounded-full"></div>
          </div>
          
          <div className="flex items-center space-x-6">
            <h1 className="text-lg font-semibold text-gray-900">IME設定</h1>
            
            <div className="flex items-center space-x-4">
              <div className="flex items-center space-x-2">
                <input
                  type="checkbox"
                  id="loginStartup"
                  checked={loginStartup}
                  onChange={(e) => setLoginStartup(e.target.checked)}
                  className="w-4 h-4 text-blue-600 rounded focus:ring-blue-500"
                />
                <label htmlFor="loginStartup" className="text-sm text-gray-700">ログイン時起動</label>
              </div>
              
              <div className="flex items-center space-x-2">
                <input
                  type="checkbox"
                  id="autoUpdate"
                  checked={autoUpdate}
                  onChange={(e) => setAutoUpdate(e.target.checked)}
                  className="w-4 h-4 text-blue-600 rounded focus:ring-blue-500"
                />
                <label htmlFor="autoUpdate" className="text-sm text-gray-700">自動アップデート</label>
              </div>
              
              <button className="bg-blue-500 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-blue-600 transition-colors whitespace-nowrap cursor-pointer">
                アップデート確認
              </button>
            </div>
          </div>
        </div>

        {/* Content */}
        <div className="p-6 h-full overflow-hidden flex flex-col">
          {/* Key Mappings */}
          <div className="mb-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">キーマッピング</h2>
            <div className="bg-gray-50 rounded-lg p-4">
              <div className="space-y-3">
                {keyMappings.map((mapping) => (
                  <div key={mapping.id} className="flex items-center justify-between p-3 bg-white rounded-lg border">
                    {mapping.isEditing ? (
                      <EditKeyMapping
                        mapping={mapping}
                        onSave={saveKeyMapping}
                        onCancel={cancelEdit}
                      />
                    ) : (
                      <>
                        <div className="flex items-center space-x-4">
                          <div className="w-8 h-8 bg-blue-500 rounded-lg flex items-center justify-center text-white font-bold text-sm">
                            ⌘
                          </div>
                          <span className="font-medium text-gray-900">{mapping.key}</span>
                          <span className="text-gray-500">→</span>
                          <span className="text-gray-700">{mapping.action}</span>
                        </div>
                        <button
                          onClick={() => editKeyMapping(mapping.id)}
                          className="text-gray-400 hover:text-gray-600 cursor-pointer"
                        >
                          <i className="ri-edit-line text-lg"></i>
                        </button>
                      </>
                    )}
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Excluded Apps */}
          <div className="flex-1 flex flex-col min-h-0">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-gray-900">除外アプリ</h2>
              <div className="flex items-center space-x-2">
                <button className="w-8 h-8 bg-green-500 text-white rounded-lg flex items-center justify-center hover:bg-green-600 transition-colors cursor-pointer">
                  <i className="ri-add-line text-lg"></i>
                </button>
                <button className="w-8 h-8 bg-red-500 text-white rounded-lg flex items-center justify-center hover:bg-red-600 transition-colors cursor-pointer">
                  <i className="ri-subtract-line text-lg"></i>
                </button>
              </div>
            </div>
            
            <div className="flex-1 bg-gray-50 rounded-lg p-4 min-h-0">
              <div className="h-full overflow-y-auto">
                <div className="space-y-2">
                  {excludedApps.map((app) => (
                    <div key={app.id} className="flex items-center space-x-3 p-3 bg-white rounded-lg border hover:bg-gray-50 transition-colors">
                      <input
                        type="checkbox"
                        id={app.id}
                        checked={app.enabled}
                        onChange={() => toggleApp(app.id)}
                        className="w-4 h-4 text-blue-600 rounded focus:ring-blue-500 cursor-pointer"
                      />
                      <label htmlFor={app.id} className="flex-1 text-gray-900 cursor-pointer select-none">
                        {app.name}
                      </label>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

interface EditKeyMappingProps {
  mapping: KeyMapping;
  onSave: (id: string, key: string, action: string) => void;
  onCancel: (id: string) => void;
}

function EditKeyMapping({ mapping, onSave, onCancel }: EditKeyMappingProps) {
  const [key, setKey] = useState(mapping.key);
  const [action, setAction] = useState(mapping.action);

  const handleSave = () => {
    onSave(mapping.id, key, action);
  };

  return (
    <div className="flex items-center space-x-3 flex-1">
      <div className="w-8 h-8 bg-blue-500 rounded-lg flex items-center justify-center text-white font-bold text-sm">
        ⌘
      </div>
      <input
        type="text"
        value={key}
        onChange={(e) => setKey(e.target.value)}
        className="flex-1 px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
      />
      <span className="text-gray-500">→</span>
      <input
        type="text"
        value={action}
        onChange={(e) => setAction(e.target.value)}
        className="flex-1 px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
      />
      <div className="flex items-center space-x-2">
        <button
          onClick={handleSave}
          className="text-green-600 hover:text-green-700 cursor-pointer"
        >
          <i className="ri-check-line text-lg"></i>
        </button>
        <button
          onClick={() => onCancel(mapping.id)}
          className="text-red-600 hover:text-red-700 cursor-pointer"
        >
          <i className="ri-close-line text-lg"></i>
        </button>
      </div>
    </div>
  );
}
