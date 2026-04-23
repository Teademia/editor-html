import { createRouter, createWebHashHistory } from 'vue-router';
import HomeView from './views/HomeView.vue';
import StudioView from './views/StudioView.vue';
import EditorView from './views/EditorView.vue';
import PlayerView from './views/PlayerView.vue';

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: '/', name: 'home', component: HomeView },
    { path: '/studio', name: 'studio', component: StudioView },
    { path: '/editor', name: 'editor', component: EditorView },
    { path: '/player', name: 'player', component: PlayerView },
  ],
});

export default router;
