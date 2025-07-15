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
       title: "OSS Tools Portal",
       description: "Comprehensive toolkit for Kubernetes environments, monitoring, and CI/CD automation",
       pagefind: true,
       social: {
         github: 'https://github.com/flexydox/flexydox.github.io'
       },
       sidebar: [
         {
           label: 'Quick Start',
           link: '/docs/quick-start/'
         },
         {
           label: 'Kubernetes Setup',
           autogenerate: { directory: 'kubernetes' }
         },
         {
           label: 'Grafana Stack',
           autogenerate: { directory: 'grafana' }
         },
         {
           label: 'CI/CD Templates',
           autogenerate: { directory: 'cicd' }
         },
         {
           label: 'Recipes',
           autogenerate: { directory: 'recipes' }
         }
       ]
     })
   ],
   output: 'static'
});