import Register from "@/register/Register.vue";
import Vote from "@/vote/Vote.vue";
import {createRouter, createWebHistory} from "vue-router";

const routes = [
    {path: '/register', component: Register,},
    {path: '/vote', component: Vote,}
]

const router = createRouter({
    history: createWebHistory(),
    routes
})

export default router