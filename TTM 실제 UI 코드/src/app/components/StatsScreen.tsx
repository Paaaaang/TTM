import { useState } from 'react';
import { ArrowLeft, TrendingUp, TrendingDown, Award, Flame } from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from 'recharts';
import { getTranslation, type Language } from '../utils/translations';

interface StatsScreenProps {
  language: Language;
  onBack: () => void;
}

export function StatsScreen({ language, onBack }: StatsScreenProps) {
  const [period, setPeriod] = useState<'week' | 'month'>('week');
  
  const t = (key: any) => getTranslation(key, language);

  // 주간 데이터
  const weeklyData = [
    { name: '월', calories: 1800, exercise: 300, weight: 72.5 },
    { name: '화', calories: 2100, exercise: 450, weight: 72.3 },
    { name: '수', calories: 1900, exercise: 200, weight: 72.4 },
    { name: '목', calories: 2200, exercise: 500, weight: 72.2 },
    { name: '금', calories: 1850, exercise: 350, weight: 72.1 },
    { name: '토', calories: 2400, exercise: 600, weight: 72.0 },
    { name: '일', calories: 2000, exercise: 400, weight: 71.9 },
  ];

  // 월간 데이터
  const monthlyData = [
    { name: '1주', calories: 14000, exercise: 2800, weight: 73.0 },
    { name: '2주', calories: 13800, exercise: 3200, weight: 72.5 },
    { name: '3주', calories: 14200, exercise: 2900, weight: 72.2 },
    { name: '4주', calories: 13500, exercise: 3100, weight: 71.9 },
  ];

  const currentData = period === 'week' ? weeklyData : monthlyData;

  const stats = [
    {
      icon: <Flame className="w-6 h-6" />,
      label: t('averageCalories'),
      value: period === 'week' ? '2,007' : '13,875',
      unit: t('kcal'),
      change: -5.2,
      color: 'from-orange-500 to-red-500',
    },
    {
      icon: <TrendingUp className="w-6 h-6" />,
      label: t('averageExercise'),
      value: period === 'week' ? '400' : '3,000',
      unit: t('kcal'),
      change: 12.5,
      color: 'from-blue-500 to-purple-500',
    },
    {
      icon: <Award className="w-6 h-6" />,
      label: t('weightChange'),
      value: period === 'week' ? '-0.6' : '-1.1',
      unit: t('kg'),
      change: -8.3,
      color: 'from-green-500 to-teal-500',
    },
  ];

  return (
    <div className="w-full max-w-md h-screen bg-gray-50 flex flex-col">
      {/* 헤더 */}
      <div className="bg-gradient-to-r from-blue-500 to-purple-600 text-white p-4">
        <div className="flex items-center gap-3 mb-4">
          <button onClick={onBack} className="p-1 hover:bg-white/20 rounded-lg transition-colors">
            <ArrowLeft className="w-6 h-6" />
          </button>
          <div>
            <h1 className="text-xl font-bold">{t('stats')}</h1>
            <p className="text-sm text-white/90">{t('myHealthData')}</p>
          </div>
        </div>

        {/* 기간 선택 */}
        <div className="flex gap-2">
          <button
            onClick={() => setPeriod('week')}
            className={`flex-1 py-2 rounded-lg font-semibold transition-all ${
              period === 'week'
                ? 'bg-white text-blue-600'
                : 'bg-white/20 text-white hover:bg-white/30'
            }`}
          >
            {t('weeklyStats')}
          </button>
          <button
            onClick={() => setPeriod('month')}
            className={`flex-1 py-2 rounded-lg font-semibold transition-all ${
              period === 'month'
                ? 'bg-white text-blue-600'
                : 'bg-white/20 text-white hover:bg-white/30'
            }`}
          >
            {t('monthlyStats')}
          </button>
        </div>
      </div>

      {/* 통계 카드 */}
      <div className="p-4 space-y-4 overflow-y-auto">
        {/* 요약 통계 */}
        <div className="grid grid-cols-1 gap-3">
          {stats.map((stat, index) => (
            <div key={index} className="bg-white rounded-xl p-4 shadow-sm border border-gray-200">
              <div className="flex items-center justify-between mb-3">
                <div className={`w-12 h-12 rounded-full bg-gradient-to-br ${stat.color} flex items-center justify-center text-white`}>
                  {stat.icon}
                </div>
                <div className="text-right">
                  <div className="text-xs text-gray-500 mb-1">{stat.label}</div>
                  <div className="text-2xl font-bold text-gray-800">
                    {stat.value} <span className="text-sm font-normal text-gray-500">{stat.unit}</span>
                  </div>
                </div>
              </div>
              <div className="flex items-center gap-1 text-sm">
                {stat.change < 0 ? (
                  <TrendingDown className="w-4 h-4 text-green-600" />
                ) : (
                  <TrendingUp className="w-4 h-4 text-blue-600" />
                )}
                <span className={stat.change < 0 ? 'text-green-600' : 'text-blue-600'}>
                  {Math.abs(stat.change)}%
                </span>
                <span className="text-gray-500">지난 {period === 'week' ? '주' : '달'} 대비</span>
              </div>
            </div>
          ))}
        </div>

        {/* 칼로리 섭취 선 그래프 */}
        <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-200">
          <h3 className="font-semibold text-gray-800 mb-4 flex items-center gap-2">
            <Flame className="w-5 h-5 text-orange-500" />
            {t('calorieIntake')}
          </h3>
          <ResponsiveContainer width="100%" height={200}>
            <LineChart data={currentData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis 
                dataKey="name" 
                stroke="#9ca3af"
                style={{ fontSize: '12px' }}
              />
              <YAxis 
                stroke="#9ca3af"
                style={{ fontSize: '12px' }}
              />
              <Tooltip 
                contentStyle={{ 
                  backgroundColor: 'white', 
                  border: '1px solid #e5e7eb',
                  borderRadius: '8px',
                  fontSize: '12px'
                }}
              />
              <Line 
                type="monotone" 
                dataKey="calories" 
                stroke="#f97316" 
                strokeWidth={3}
                dot={{ fill: '#f97316', r: 5 }}
                activeDot={{ r: 7 }}
                name="칼로리 (kcal)"
              />
            </LineChart>
          </ResponsiveContainer>
        </div>

        {/* 운동 소모 칼로리 선 그래프 */}
        <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-200">
          <h3 className="font-semibold text-gray-800 mb-4 flex items-center gap-2">
            <TrendingUp className="w-5 h-5 text-blue-500" />
            {t('exerciseBurn')}
          </h3>
          <ResponsiveContainer width="100%" height={200}>
            <LineChart data={currentData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis 
                dataKey="name" 
                stroke="#9ca3af"
                style={{ fontSize: '12px' }}
              />
              <YAxis 
                stroke="#9ca3af"
                style={{ fontSize: '12px' }}
              />
              <Tooltip 
                contentStyle={{ 
                  backgroundColor: 'white', 
                  border: '1px solid #e5e7eb',
                  borderRadius: '8px',
                  fontSize: '12px'
                }}
              />
              <Line 
                type="monotone" 
                dataKey="exercise" 
                stroke="#3b82f6" 
                strokeWidth={3}
                dot={{ fill: '#3b82f6', r: 5 }}
                activeDot={{ r: 7 }}
                name="운동 (kcal)"
              />
            </LineChart>
          </ResponsiveContainer>
        </div>

        {/* 체중 변화 선 그래프 */}
        <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-200 mb-4">
          <h3 className="font-semibold text-gray-800 mb-4 flex items-center gap-2">
            <Award className="w-5 h-5 text-green-500" />
            {t('weightChange')}
          </h3>
          <ResponsiveContainer width="100%" height={200}>
            <LineChart data={currentData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis 
                dataKey="name" 
                stroke="#9ca3af"
                style={{ fontSize: '12px' }}
              />
              <YAxis 
                stroke="#9ca3af"
                style={{ fontSize: '12px' }}
                domain={['dataMin - 0.5', 'dataMax + 0.5']}
              />
              <Tooltip 
                contentStyle={{ 
                  backgroundColor: 'white', 
                  border: '1px solid #e5e7eb',
                  borderRadius: '8px',
                  fontSize: '12px'
                }}
              />
              <Line 
                type="monotone" 
                dataKey="weight" 
                stroke="#10b981" 
                strokeWidth={3}
                dot={{ fill: '#10b981', r: 5 }}
                activeDot={{ r: 7 }}
                name="체중 (kg)"
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
}