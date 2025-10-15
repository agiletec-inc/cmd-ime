
'use client';

import Link from 'next/link';

export default function Home() {
  return (
    <div className="min-h-screen bg-white">
      {/* Header */}
      <header className="px-6 py-6">
        <div className="max-w-6xl mx-auto flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 bg-black rounded-xl flex items-center justify-center">
              <span className="text-white font-bold text-lg">⌘</span>
            </div>
            <span className="font-semibold text-2xl text-gray-900">⌘IME</span>
          </div>
          <nav className="hidden md:flex items-center space-x-8">
            <Link href="#how-it-works" className="text-gray-600 hover:text-gray-900 transition-colors cursor-pointer">仕組み</Link>
            <Link href="#download" className="text-gray-600 hover:text-gray-900 transition-colors cursor-pointer">ダウンロード</Link>
            <button className="bg-black text-white px-6 py-2.5 rounded-lg hover:bg-gray-800 transition-all whitespace-nowrap cursor-pointer font-medium">
              今すぐ試す
            </button>
          </nav>
        </div>
      </header>

      {/* Hero Section */}
      <section className="max-w-6xl mx-auto px-6 py-24 text-center">
        <div className="max-w-4xl mx-auto">
          <h1 className="text-5xl md:text-7xl font-bold text-gray-900 mb-8 leading-tight tracking-tight">
            左⌘、右⌘で
            <br />
            <span className="text-gray-500">瞬時に切り替え</span>
          </h1>
          <p className="text-xl md:text-2xl text-gray-600 mb-12 leading-relaxed max-w-3xl mx-auto">
            USキーボードの⌘キーを活用した、究極にシンプルなIME切り替えアプリ。<br />
            既存のショートカットに干渉せず、日本語⇄英語を自然に切り替え。
          </p>
          
          {/* CTA */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center mb-16">
            <button className="bg-black text-white px-8 py-4 rounded-xl text-lg font-semibold hover:bg-gray-800 transition-all whitespace-nowrap cursor-pointer">
              無料ダウンロード
            </button>
            <button className="border border-gray-300 text-gray-700 px-8 py-4 rounded-xl text-lg font-semibold hover:border-gray-400 hover:bg-gray-50 transition-all whitespace-nowrap cursor-pointer">
              動作を見る
            </button>
          </div>
        </div>

        {/* Keyboard Visual */}
        <div className="max-w-4xl mx-auto">
          <div className="bg-gray-50 rounded-3xl p-12 mb-12">
            <div className="relative">
              {/* US Keyboard Layout */}
              <div className="bg-white rounded-2xl p-8 shadow-sm border">
                <div className="text-center mb-6">
                  <span className="text-sm font-medium text-gray-500 bg-gray-100 px-3 py-1 rounded-full">MacBook Pro USキーボードレイアウト</span>
                </div>
                
                {/* Keyboard Keys - Compact Mac Layout */}
                <div className="inline-block bg-gray-900 rounded-lg p-2">
                  <div className="space-y-0.5">
                    {/* Function Keys Row */}
                    <div className="flex gap-0.5 mb-1">
                      <div className="w-7 h-5 bg-gray-700 rounded-sm flex items-center justify-center text-xs font-medium text-gray-300">esc</div>
                      <div className="w-2"></div>
                      {['F1', 'F2', 'F3', 'F4'].map((key, i) => (
                        <div key={i} className="w-7 h-5 bg-gray-700 rounded-sm flex items-center justify-center text-xs font-medium text-gray-300">{key}</div>
                      ))}
                      <div className="w-2"></div>
                      {['F5', 'F6', 'F7', 'F8'].map((key, i) => (
                        <div key={i} className="w-7 h-5 bg-gray-700 rounded-sm flex items-center justify-center text-xs font-medium text-gray-300">{key}</div>
                      ))}
                      <div className="w-2"></div>
                      {['F9', 'F10', 'F11', 'F12'].map((key, i) => (
                        <div key={i} className="w-7 h-5 bg-gray-700 rounded-sm flex items-center justify-center text-xs font-medium text-gray-300">{key}</div>
                      ))}
                      <div className="w-2"></div>
                      <div className="w-7 h-5 bg-gray-700 rounded-sm"></div>
                    </div>

                    {/* Number Row */}
                    <div className="flex gap-0.5">
                      <div className="w-7 h-7 bg-gray-700 rounded-sm flex items-center justify-center text-xs font-medium text-gray-300">`</div>
                      {['1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '='].map((key, i) => (
                        <div key={i} className="w-7 h-7 bg-gray-700 rounded-sm flex items-center justify-center text-xs font-medium text-gray-300">{key}</div>
                      ))}
                      <div className="w-12 h-7 bg-gray-700 rounded-sm flex items-center justify-center text-xs font-medium text-gray-300">delete</div>
                    </div>
                    
                    {/* QWERTY Row */}
                    <div className="flex gap-0.5">
                      <div className="w-10 h-7 bg-gray-700 rounded-sm flex items-center justify-center text-xs font-medium text-gray-300">tab</div>
                      {['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '[', ']'].map((key, i) => (
                        <div key={i} className="w-7 h-7 bg-gray-700 rounded-sm flex items-center justify-center text-xs font-medium text-gray-300">{key}</div>
                      ))}
                      <div className="w-9 h-7 bg-gray-700 rounded-sm flex items-center justify-center text-xs font-medium text-gray-300">\\</div>
                    </div>
                    
                    {/* ASDF Row */}
                    <div className="flex gap-0.5">
                      <div className="w-12 h-7 bg-gray-700 rounded-sm flex items-center justify-center text-xs font-medium text-gray-300">caps</div>
                      {['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ';', "'"].map((key, i) => (
                        <div key={i} className="w-7 h-7 bg-gray-700 rounded-sm flex items-center justify-center text-xs font-medium text-gray-300">{key}</div>
                      ))}
                      <div className="w-14 h-7 bg-gray-700 rounded-sm flex items-center justify-center text-xs font-medium text-gray-300">return</div>
                    </div>
                    
                    {/* ZXCV Row */}
                    <div className="flex gap-0.5">
                      <div className="w-16 h-7 bg-gray-700 rounded-sm flex items-center justify-center text-xs font-medium text-gray-300">shift</div>
                      {['Z', 'X', 'C', 'V', 'B', 'N', 'M', ',', '.', '/'].map((key, i) => (
                        <div key={i} className="w-7 h-7 bg-gray-700 rounded-sm flex items-center justify-center text-xs font-medium text-gray-300">{key}</div>
                      ))}
                      <div className="w-16 h-7 bg-gray-700 rounded-sm flex items-center justify-center text-xs font-medium text-gray-300">shift</div>
                    </div>
                    
                    {/* Bottom Row */}
                    <div className="flex gap-0.5">
                      <div className="w-6 h-7 bg-gray-700 rounded-sm flex items-center justify-center text-xs font-medium text-gray-300">fn</div>
                      <div className="w-6 h-7 bg-gray-700 rounded-sm flex items-center justify-center text-xs font-medium text-gray-300">⌃</div>
                      <div className="w-6 h-7 bg-gray-700 rounded-sm flex items-center justify-center text-xs font-medium text-gray-300">⌥</div>
                      
                      {/* Left CMD - 英語入力 */}
                      <div className="w-10 h-7 bg-green-500 rounded-sm flex items-center justify-center text-xs font-bold text-white shadow-lg">
                        ⌘
                      </div>
                      
                      {/* Space - Very long */}
                      <div className="w-32 h-7 bg-gray-700 rounded-sm"></div>
                      
                      {/* Right CMD - 日本語入力 */}
                      <div className="w-10 h-7 bg-blue-500 rounded-sm flex items-center justify-center text-xs font-bold text-white shadow-lg">
                        ⌘
                      </div>
                      
                      <div className="w-6 h-7 bg-gray-700 rounded-sm flex items-center justify-center text-xs font-medium text-gray-300">⌥</div>
                      
                      {/* Arrow Keys - Compact Mac layout */}
                      <div className="flex flex-col ml-0.5">
                        <div className="w-6 h-3.5 bg-gray-700 rounded-sm flex items-center justify-center mb-0.5">
                          <div className="w-2 h-2 border-t border-r border-gray-300 transform -rotate-45"></div>
                        </div>
                        <div className="flex gap-0">
                          <div className="w-6 h-3.5 bg-gray-700 rounded-sm flex items-center justify-center">
                            <div className="w-2 h-2 border-t border-r border-gray-300 transform rotate-45"></div>
                          </div>
                          <div className="w-6 h-3.5 bg-gray-700 rounded-sm flex items-center justify-center">
                            <div className="w-2 h-2 border-t border-r border-gray-300 transform rotate-135"></div>
                          </div>
                          <div className="w-6 h-3.5 bg-gray-700 rounded-sm flex items-center justify-center">
                            <div className="w-2 h-2 border-t border-r border-gray-300 transform -rotate-135"></div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                
                {/* Labels */}
                <div className="flex justify-center items-center mt-8 space-x-12">
                  <div className="text-center">
                    <div className="w-12 h-12 bg-green-500 rounded-xl flex items-center justify-center text-white font-bold text-lg mb-2 mx-auto">
                      ⌘
                    </div>
                    <span className="text-sm font-medium text-green-600">英語入力</span>
                  </div>
                  <div className="text-center">
                    <div className="w-12 h-12 bg-blue-500 rounded-xl flex items-center justify-center text-white font-bold text-lg mb-2 mx-auto">
                      ⌘
                    </div>
                    <span className="text-sm font-medium text-blue-600">日本語入力</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* How It Works */}  
      <section id="how-it-works" className="bg-gray-50 py-24">
        <div className="max-w-6xl mx-auto px-6">
          <div className="text-center mb-16">
            <h2 className="text-4xl md:text-5xl font-bold text-gray-900 mb-6">
              3つのシンプルな特徴
            </h2>
            <p className="text-xl text-gray-600">
              既存のワークフローを一切妨げない設計
            </p>  
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            <div className="bg-white p-8 rounded-2xl shadow-sm">
              <div className="w-16 h-16 bg-green-50 rounded-2xl flex items-center justify-center mb-6 mx-auto">
                <i className="ri-english-input text-3xl text-green-600"></i>
              </div>
              <h3 className="text-2xl font-bold text-gray-900 mb-4 text-center">左⌘キー単独押し</h3>
              <p className="text-gray-600 text-center leading-relaxed">
                左の⌘キーを単独で押すと英語直接入力モードに切り替え。⌘+Cなどの組み合わせには影響しません
              </p>
            </div>

            <div className="bg-white p-8 rounded-2xl shadow-sm">
              <div className="w-16 h-16 bg-blue-50 rounded-2xl flex items-center justify-center mb-6 mx-auto">
                <i className="ri-keyboard-line text-3xl text-blue-600"></i>
              </div>
              <h3 className="text-2xl font-bold text-gray-900 mb-4 text-center">右⌘キー単独押し</h3>
              <p className="text-gray-600 text-center leading-relaxed">
                右の⌘キーを単独で押すと日本語入力モードに切り替え。既存ショートカットは完全保護
              </p>
            </div>

            <div className="bg-white p-8 rounded-2xl shadow-sm">
              <div className="w-16 h-16 bg-purple-50 rounded-2xl flex items-center justify-center mb-6 mx-auto">
                <i className="ri-flashlight-line text-3xl text-purple-600"></i>
              </div>
              <h3 className="text-2xl font-bold text-gray-900 mb-4 text-center">0.001秒切り替え</h3>
              <p className="text-gray-600 text-center leading-relaxed">
                Apple Silicon最適化により、思考速度でIMEが切り替わり。タイピングフローを妨げません
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Settings Preview */}
      <section className="py-24">
        <div className="max-w-6xl mx-auto px-6">
          <div className="text-center mb-16">
            <h2 className="text-4xl md:text-5xl font-bold text-gray-900 mb-6">
              設定は驚くほどシンプル
            </h2>
            <p className="text-xl text-gray-600">
              インストール後、2クリックで完了
            </p>
          </div>

          <div className="max-w-4xl mx-auto">
            <div className="bg-white rounded-3xl shadow-xl border p-8">
              {/* Mock Settings UI */}
              <div className="bg-gray-50 rounded-2xl p-6">
                <div className="flex items-center space-x-3 mb-6">
                  <div className="w-3 h-3 bg-red-500 rounded-full"></div>
                  <div className="w-3 h-3 bg-yellow-500 rounded-full"></div>
                  <div className="w-3 h-3 bg-green-500 rounded-full"></div>
                  <span className="text-gray-600 text-sm ml-4">⌘IME 設定</span>
                </div>
                
                <div className="bg-white rounded-xl p-6 space-y-6">
                  <h3 className="text-xl font-semibold text-gray-900">キー割り当て</h3>
                  
                  <div className="space-y-4">
                    <div className="flex items-center justify-between p-4 bg-green-50 rounded-lg">
                      <div className="flex items-center space-x-3">
                        <div className="w-8 h-8 bg-green-500 rounded-lg flex items-center justify-center text-white font-bold">
                          ⌘
                        </div>
                        <span className="font-medium text-gray-900">左⌘キー単独押し</span>
                      </div>
                      <div className="flex items-center space-x-2">
                        <span className="text-sm text-gray-600">→</span>
                        <span className="bg-white px-3 py-1 rounded-md text-sm font-medium border">英語入力</span>
                      </div>
                    </div>
                    
                    <div className="flex items-center justify-between p-4 bg-blue-50 rounded-lg">
                      <div className="flex items-center space-x-3">
                        <div className="w-8 h-8 bg-blue-500 rounded-lg flex items-center justify-center text-white font-bold">
                          ⌘
                        </div>
                        <span className="font-medium text-gray-900">右⌘キー単独押し</span>
                      </div>
                      <div className="flex items-center space-x-2">
                        <span className="text-sm text-gray-600">→</span>
                        <span className="bg-white px-3 py-1 rounded-md text-sm font-medium border">日本語入力</span>
                      </div>
                    </div>
                  </div>
                  
                  <div className="pt-4 border-t">
                    <div className="flex items-center justify-between">
                      <span className="text-sm text-gray-600">既存ショートカット保護</span>
                      <div className="w-12 h-6 bg-green-500 rounded-full flex items-center justify-end pr-1">
                        <div className="w-4 h-4 bg-white rounded-full"></div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Download CTA */}
      <section id="download" className="bg-black text-white py-24">
        <div className="max-w-6xl mx-auto px-6 text-center">
          <h2 className="text-4xl md:text-6xl font-bold mb-8">
            今すぐ体験してみませんか？
          </h2>
          <p className="text-xl text-gray-300 mb-12 max-w-2xl mx-auto">
            macOS 12.0+対応、Apple Silicon完全最適化
            <br />
            30日間返金保証付き
          </p>

          <div className="space-y-4 max-w-md mx-auto">
            <button className="w-full bg-white text-black py-4 rounded-xl text-lg font-semibold hover:bg-gray-100 transition-all whitespace-nowrap cursor-pointer">
              <i className="ri-download-line mr-2"></i>
              無料ダウンロード
            </button>
            <p className="text-sm text-gray-400">
              14日間無料体験 • 2.1MB • Intel & Apple Silicon
            </p>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-gray-50 py-16">
        <div className="max-w-6xl mx-auto px-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="w-8 h-8 bg-black rounded-lg flex items-center justify-center">
                <span className="text-white font-bold text-sm">⌘</span>
              </div>
              <span className="font-semibold text-xl text-gray-900">⌘IME</span>
            </div>
            
            <div className="flex items-center space-x-8 text-sm text-gray-600">
              <Link href="#" className="hover:text-gray-900 transition-colors cursor-pointer">プライバシー</Link>
              <Link href="#" className="hover:text-gray-900 transition-colors cursor-pointer">利用規約</Link>
              <Link href="#" className="hover:text-gray-900 transition-colors cursor-pointer">サポート</Link>
            </div>
          </div>
          
          <div className="border-t border-gray-200 mt-8 pt-8 text-center text-sm text-gray-500">
            <p>&copy; 2024 ⌘IME. macOSでのUSキーボード最適化IME</p>
          </div>
        </div>
      </footer>
    </div>
  );
}
