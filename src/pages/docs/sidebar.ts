export const sidebarConfig = [
  { label: "Home", link: "/" },
  {
    label: "Getting Started",
    items: [
      { label: "Core Concepts", link: "/docs/core-concepts" },
      { label: "Usage", link: "/docs/usage" },
      { label: "Roadmap", link: "/docs/roadmap" },
      { label: "Examples", link: "https://examples.flexydox.org", attrs: { target: '_blank', style: 'font-style: italic' }, },
      
    ]
  },
  {
    label: "Configuration",
    items: [
      { label: "Configuration file", link: "/docs/configuration" },
      { label: "CLI reference", link: "/docs/cli" }
    ]
  },
  {
    label: "Development",
    items: [
      { label: "Development Guide", link: "/docs/development" }
    ]
  }
];