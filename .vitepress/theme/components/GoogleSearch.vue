<template>
    <!-- Vue doesn't like the built in script thing. Use the component thing to get around it. -->
    <component :is="'script'" async src="https://cse.google.com/cse.js?cx=d55df9aacc78f45ed"></component>
    <div>
        <div class="gcse-search"></div>
    </div>
</template>
<style>
/* Overrides the default Google search box styles */
.gsc-control-cse {
    background-color: inherit !important;
    border: none !important;
    color: #000000 !important;
}
.gsc-completion-container {
    background-color: #ffffff !important;
    border: 1px solid #000000 !important;
    color: #000000 !important;
}
</style>