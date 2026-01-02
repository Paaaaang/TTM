import { useState } from 'react';
import logo from 'figma:asset/442a3d3a81070f8c9fd851b78ebb9522d24310ec.png';
import { LoginScreen } from './components/LoginScreen';
import { Login } from './components/Login';
import { Signup } from './components/Signup';
import { Welcome } from './components/Welcome';
import { UserInfoStep1 } from './components/UserInfoStep1';
import { UserInfoStep2 } from './components/UserInfoStep2';
import { UserInfoStep3 } from './components/UserInfoStep3';
import { UserInfoStep4 } from './components/UserInfoStep4';
import { MainScreen } from './components/MainScreen';
import { MealDetailScreen } from './components/MealDetailScreen';
import { ExerciseDetailScreen } from './components/ExerciseDetailScreen';
import { CommunityHomeScreen } from './components/CommunityHomeScreen';
import { StatsScreen } from './components/StatsScreen';
import { AICoachScreen } from './components/AICoachScreen';
import { ProfileScreen } from './components/ProfileScreen';
import { CreatePostScreen } from './components/CreatePostScreen';
import { PostDetailScreen } from './components/PostDetailScreen';
import { UserProfileScreen } from './components/UserProfileScreen';
import { ActivityHistoryScreen } from './components/ActivityHistoryScreen';
import { MealRecordDetailScreen } from './components/MealRecordDetailScreen';
import { WorkoutRecordDetailScreen } from './components/WorkoutRecordDetailScreen';
import { SettingsScreen } from './components/SettingsScreen';
import { FriendsListScreen } from './components/FriendsListScreen';
import { HelpScreen } from './components/HelpScreen';
import { CameraScreen } from './components/CameraScreen';
import { getCurrentLanguage, type Language } from './utils/translations';

type Screen = 'welcome' | 'login' | 'signup' | 'user-welcome' | 'user-info-step1' | 'user-info-step2' | 'user-info-step3' | 'user-info-step4' | 'main' | 'meal-detail' | 'exercise-detail' | 'community-home' | 'stats' | 'ai-coach' | 'profile' | 'create-post' | 'post-detail' | 'user-profile' | 'activity-history' | 'meal-record-detail' | 'workout-record-detail' | 'settings' | 'friends-list' | 'help' | 'camera';

interface Post {
  id: string;
  author: string;
  authorAvatar: string;
  group: string;
  content: string;
  image?: string;
  time: string;
  likes: number;
  comments: number;
  shares: number;
}

export default function App() {
  const [currentScreen, setCurrentScreen] = useState<Screen>('welcome');
  const [screenHistory, setScreenHistory] = useState<Screen[]>([]);
  const [language, setLanguage] = useState<Language>(getCurrentLanguage());
  const [userNickname, setUserNickname] = useState('');
  const [userInfo, setUserInfo] = useState<any>({});
  const [currentMealType, setCurrentMealType] = useState<'breakfast' | 'lunch' | 'dinner' | 'snack'>('breakfast');
  const [currentMealTitle, setCurrentMealTitle] = useState('아침');
  const [mealData, setMealData] = useState<any>({
    breakfast: [],
    lunch: [],
    dinner: [],
    snack: [],
  });
  const [exerciseData, setExerciseData] = useState<any[]>([]);
  const [communityPosts, setCommunityPosts] = useState<Post[]>([]);
  const [selectedPost, setSelectedPost] = useState<Post | null>(null);
  const [selectedUserProfile, setSelectedUserProfile] = useState<string>('');
  const [currentPostId, setCurrentPostId] = useState<string>('');
  const [currentViewingUser, setCurrentViewingUser] = useState<string>('');
  const [selectedMealRecord, setSelectedMealRecord] = useState<any>(null);
  const [selectedWorkoutRecord, setSelectedWorkoutRecord] = useState<any>(null);
  const [activityInitialTab, setActivityInitialTab] = useState<'meals' | 'workouts' | 'posts' | 'likes'>('meals');

  const navigateTo = (screen: Screen) => {
    setScreenHistory([...screenHistory, currentScreen]);
    setCurrentScreen(screen);
  };

  const navigateBack = () => {
    if (screenHistory.length > 0) {
      const previousScreen = screenHistory[screenHistory.length - 1];
      setScreenHistory(screenHistory.slice(0, -1));
      setCurrentScreen(previousScreen);
    }
  };

  const handleSignupComplete = (nickname: string) => {
    setUserNickname(nickname);
    // 회원가입 시 currentUser에 닉네임 먼저 저장
    const users = JSON.parse(localStorage.getItem('users') || '[]');
    const newUser = users[users.length - 1]; // 가장 최근에 추가된 사용자
    if (newUser) {
      localStorage.setItem('currentUser', JSON.stringify(newUser));
    }
    setCurrentScreen('user-welcome');
  };

  const handleLoginSuccess = (nickname: string) => {
    setUserNickname(nickname);
    setCurrentScreen('main');
  };

  const handleUserInfoStep1Complete = (data: any) => {
    setUserInfo({ ...userInfo, ...data });
    setCurrentScreen('user-info-step2');
  };

  const handleUserInfoStep2Complete = (data: any) => {
    setUserInfo({ ...userInfo, ...data });
    setCurrentScreen('user-info-step3');
  };

  const handleUserInfoStep3Complete = (data: any) => {
    setUserInfo({ ...userInfo, ...data });
    setCurrentScreen('user-info-step4');
  };

  const handleUserInfoStep4Complete = (data: any) => {
    const completeUserInfo = { ...userInfo, ...data };
    setUserInfo(completeUserInfo);
    
    // currentUser에 모든 정보 업데이트
    const currentUser = JSON.parse(localStorage.getItem('currentUser') || '{}');
    const updatedUser = {
      ...currentUser,
      ...completeUserInfo,
    };
    localStorage.setItem('currentUser', JSON.stringify(updatedUser));
    
    // users 배열에서도 업데이트
    const users = JSON.parse(localStorage.getItem('users') || '[]');
    const updatedUsers = users.map((u: any) => 
      u.username === currentUser.username ? updatedUser : u
    );
    localStorage.setItem('users', JSON.stringify(updatedUsers));
    
    setCurrentScreen('main');
  };

  const handleMealClick = (type: 'breakfast' | 'lunch' | 'dinner' | 'snack', title: string) => {
    setCurrentMealType(type);
    setCurrentMealTitle(title);
    setCurrentScreen('meal-detail');
  };

  const handleMealSave = (foods: any[]) => {
    setMealData({
      ...mealData,
      [currentMealType]: foods,
    });
    setCurrentScreen('main');
  };

  const handleExerciseClick = () => {
    setCurrentScreen('exercise-detail');
  };

  const handleExerciseSave = (exercises: any[]) => {
    setExerciseData([...exerciseData, ...exercises]);
    setCurrentScreen('main');
  };

  const handleCreatePost = (postData: { group: string; content: string; images: string[] }) => {
    const currentUser = JSON.parse(localStorage.getItem('currentUser') || '{}');
    const newPost: Post = {
      id: Date.now().toString(),
      author: currentUser.nickname || '익명',
      authorAvatar: currentUser.nickname ? currentUser.nickname[0] : '😊',
      group: postData.group,
      content: postData.content,
      image: postData.images[0],
      time: '방금 전',
      likes: 0,
      comments: 0,
      shares: 0,
    };
    
    setCommunityPosts([newPost, ...communityPosts]);
    setCurrentScreen('community-home');
  };

  const handleUpdatePost = (postId: string, content: string) => {
    setCommunityPosts(communityPosts.map(post => 
      post.id === postId ? { ...post, content } : post
    ));
  };

  const handleDeletePost = (postId: string) => {
    setCommunityPosts(communityPosts.filter(post => post.id !== postId));
  };

  return (
    <div className="size-full flex items-center justify-center bg-gradient-to-br from-green-50 to-blue-50 overflow-y-auto">
      {currentScreen === 'welcome' && (
        <LoginScreen 
          logo={logo} 
          onLogin={() => setCurrentScreen('login')}
          onSignup={() => setCurrentScreen('signup')}
          language={language}
        />
      )}
      {currentScreen === 'login' && (
        <Login 
          logo={logo}
          onBack={() => setCurrentScreen('welcome')}
          onLoginSuccess={handleLoginSuccess}
          language={language}
        />
      )}
      {currentScreen === 'signup' && (
        <Signup 
          logo={logo}
          onBack={() => setCurrentScreen('welcome')}
          onSignupComplete={handleSignupComplete}
        />
      )}
      {currentScreen === 'user-welcome' && (
        <Welcome 
          logo={logo}
          nickname={userNickname}
          onNext={() => setCurrentScreen('user-info-step1')}
          onSkip={() => setCurrentScreen('main')}
          language={language}
        />
      )}
      {currentScreen === 'user-info-step1' && (
        <UserInfoStep1 
          onNext={handleUserInfoStep1Complete}
        />
      )}
      {currentScreen === 'user-info-step2' && (
        <UserInfoStep2 
          onNext={handleUserInfoStep2Complete}
          onBack={() => setCurrentScreen('user-info-step1')}
        />
      )}
      {currentScreen === 'user-info-step3' && (
        <UserInfoStep3 
          onNext={handleUserInfoStep3Complete}
          onBack={() => setCurrentScreen('user-info-step2')}
        />
      )}
      {currentScreen === 'user-info-step4' && (
        <UserInfoStep4 
          onNext={handleUserInfoStep4Complete}
          onBack={() => setCurrentScreen('user-info-step3')}
        />
      )}
      {currentScreen === 'main' && (
        <MainScreen 
          language={language}
          onMealClick={handleMealClick}
          mealData={mealData}
          onExerciseClick={handleExerciseClick}
          exerciseData={exerciseData}
          onCommunityClick={() => navigateTo('community-home')}
          onStatsClick={() => navigateTo('stats')}
          onAICoachClick={() => navigateTo('ai-coach')}
          onProfileClick={() => navigateTo('profile')}
          onCameraClick={() => navigateTo('camera')}
        />
      )}
      {currentScreen === 'meal-detail' && (
        <MealDetailScreen 
          mealType={currentMealType}
          mealTitle={currentMealTitle}
          onBack={() => setCurrentScreen('main')}
          onSave={handleMealSave}
        />
      )}
      {currentScreen === 'exercise-detail' && (
        <ExerciseDetailScreen 
          onBack={() => setCurrentScreen('main')}
          onSave={handleExerciseSave}
        />
      )}
      {currentScreen === 'community-home' && (
        <CommunityHomeScreen 
          language={language}
          onBack={navigateBack}
          onCreatePost={() => navigateTo('create-post')}
          posts={communityPosts}
          onUpdatePost={handleUpdatePost}
          onDeletePost={handleDeletePost}
          onPostClick={(postId) => {
            const post = communityPosts.find(p => p.id === postId);
            if (post) {
              setSelectedPost(post);
              navigateTo('post-detail');
            }
          }}
          onViewProfile={(author) => {
            setSelectedUserProfile(author);
            navigateTo('user-profile');
          }}
        />
      )}
      {currentScreen === 'stats' && (
        <StatsScreen 
          language={language}
          onBack={navigateBack}
        />
      )}
      {currentScreen === 'ai-coach' && (
        <AICoachScreen 
          language={language}
          onBack={navigateBack}
        />
      )}
      {currentScreen === 'profile' && (
        <ProfileScreen 
          language={language}
          onBack={navigateBack}
          onViewActivity={() => navigateTo('activity-history')}
          onViewSettings={() => navigateTo('settings')}
        />
      )}
      {currentScreen === 'create-post' && (
        <CreatePostScreen 
          onBack={() => setCurrentScreen('community-home')}
          onCreatePost={handleCreatePost}
        />
      )}
      {currentScreen === 'post-detail' && (
        <PostDetailScreen 
          post={communityPosts.find(p => p.id === currentPostId)!}
          onBack={() => setCurrentScreen('community-home')}
          onEdit={() => {
            // 수정 기능은 여기서 처리
            const newContent = prompt('수정할 내용을 입력하세요:', communityPosts.find(p => p.id === currentPostId)?.content);
            if (newContent) {
              handleUpdatePost(currentPostId, newContent);
            }
          }}
          onDelete={() => {
            handleDeletePost(currentPostId);
            setCurrentScreen('community-home');
          }}
          onViewProfile={(username) => {
            setCurrentViewingUser(username);
            setCurrentScreen('user-profile');
          }}
          isMyPost={communityPosts.find(p => p.id === currentPostId)?.author === JSON.parse(localStorage.getItem('currentUser') || '{}').nickname}
        />
      )}
      {currentScreen === 'user-profile' && (
        <UserProfileScreen 
          username={currentViewingUser}
          userPosts={communityPosts}
          onBack={() => setCurrentScreen('community-home')}
          onPostClick={(postId) => {
            setCurrentPostId(postId);
            setCurrentScreen('post-detail');
          }} 
        />
      )}
      {currentScreen === 'activity-history' && (
        <ActivityHistoryScreen 
          onBack={navigateBack}
          onMealClick={(meal) => {
            // 선택한 식단 기록 저장 후 상세 화면으로 이동
            setSelectedMealRecord(meal);
            navigateTo('meal-record-detail');
          }}
          onWorkoutClick={(workout) => {
            // 선택한 운동 기록 저장 후 상세 화면으로 이동
            setSelectedWorkoutRecord(workout);
            navigateTo('workout-record-detail');
          }}
          onPostClick={(postId) => {
            // 내가 쓴 게시물 상세로 이동
            setCurrentPostId(postId);
            navigateTo('post-detail');
          }}
          onUserClick={(username) => {
            // 다른 사람 프로필로 이동
            setCurrentViewingUser(username);
            navigateTo('user-profile');
          }}
          initialTab={activityInitialTab}
        />
      )}
      {currentScreen === 'meal-record-detail' && selectedMealRecord && (
        <MealRecordDetailScreen 
          meal={selectedMealRecord}
          onBack={navigateBack}
        />
      )}
      {currentScreen === 'workout-record-detail' && selectedWorkoutRecord && (
        <WorkoutRecordDetailScreen 
          workout={selectedWorkoutRecord}
          onBack={navigateBack}
        />
      )}
      {currentScreen === 'settings' && (
        <SettingsScreen 
          onBack={navigateBack}
          onViewFriends={() => navigateTo('friends-list')}
          onViewHelp={() => navigateTo('help')}
          onLanguageChange={(newLang) => setLanguage(newLang)}
          onLogout={() => {
            localStorage.removeItem('currentUser');
            setScreenHistory([]);
            setCurrentScreen('welcome');
          }}
          onDeleteAccount={() => {
            const users = JSON.parse(localStorage.getItem('users') || '[]');
            const currentUser = JSON.parse(localStorage.getItem('currentUser') || '{}');
            const updatedUsers = users.filter((u: any) => u.email !== currentUser.email);
            localStorage.setItem('users', JSON.stringify(updatedUsers));
            localStorage.removeItem('currentUser');
            setScreenHistory([]);
            setCurrentScreen('welcome');
          }}
        />
      )}
      {currentScreen === 'friends-list' && (
        <FriendsListScreen 
          onBack={navigateBack}
        />
      )}
      {currentScreen === 'help' && (
        <HelpScreen 
          onBack={navigateBack}
        />
      )}
      {currentScreen === 'camera' && (
        <CameraScreen 
          language={language}
          onBack={navigateBack}
        />
      )}
    </div>
  );
}