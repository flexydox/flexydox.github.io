import { defineConfig } from 'astro/config';
import starlight from "@astrojs/starlight";
import tailwind from "@astrojs/tailwind";
import sitemap from "@astrojs/sitemap";

// https://astro.build/config
export default defineConfig({
   site: 'https://flexydox.github.io',
   integrations: [
     tailwind(),
     sitemap(),
     starlight({
       title: "Flexydox",
       description: "Comprehensive toolkit for Kubernetes environments, monitoring, and CI/CD automation",
       pagefind: true,
       social: {
         github: 'https://github.com/flexydox/flexydox.github.io'
       },
       defaultLocale: 'root',
       locales: {
         root: {
           label: 'English',
           lang: 'en',
         },
         cs: {
           label: 'Čeština',
           lang: 'cs',
         },
       },
       sidebar: [
         {
           label: 'Quick Start',
           translations: {
             cs: 'Rychlý start'
           },
           link: '/docs/quick-start/'
         },
         {
           label: 'Kubernetes Setup',
           translations: {
             cs: 'Kubernetes nastavení'
           },
           autogenerate: { directory: 'kubernetes' }
         },
         {
           label: 'Grafana Stack',
           translations: {
             cs: 'Grafana Stack'
           },
           autogenerate: { directory: 'grafana' }
         },
         {
           label: 'CI/CD Templates',
           translations: {
             cs: 'CI/CD šablony'
           },
           autogenerate: { directory: 'cicd' }
         },
         {
           label: 'Recipes',
           translations: {
             cs: 'Recepty'
           },
           autogenerate: { directory: 'recipes' }
         }
       ]
     })
   ],
   output: 'static'
});