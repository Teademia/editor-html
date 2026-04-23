import { createApp } from 'vue';
import App from './App.vue';
import router from './router';
import './styles.css';
import 'drawflow/dist/drawflow.min.css';

createApp(App).use(router).mount('#app');
