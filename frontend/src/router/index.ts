import { createRouter, createWebHistory } from 'vue-router'
import Home from '../views/Home.vue'

const routes = [
  {
    path: '/',
    name: 'Home',
    component: Home
  },
  {
    path: '/novels',
    name: 'Novels',
    component: () => import('../views/Novels.vue')
  },
  {
    path: '/ai-generator',
    name: 'AIGenerator',
    component: () => import('../views/AIContentGenerator.vue')
  },
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/Auth.vue')
  },
  {
    path: '/register',
    name: 'Register',
    component: () => import('../views/Auth.vue')
  },
  {
    path: '/novel/:id/edit',
    name: 'NovelEdit',
    component: () => import('../views/NovelEditor.vue')
  },
  {
    path: '/characters',
    name: 'Characters',
    component: () => import('../views/Characters.vue')
  },
  {
    path: '/tools',
    name: 'Tools',
    component: () => import('../views/Tools.vue')
  },
  {
    path: '/about',
    name: 'About',
    component: () => import('../views/About.vue')
  }
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes
})

export default router
