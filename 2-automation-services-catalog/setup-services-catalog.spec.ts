import { test, expect } from '@playwright/test';

// We are using self signed certificates for our demo environment
test.use({
  ignoreHTTPSErrors: true
});

test('test', async ({ page }) => {

    // Open the automation service catalog dashboard
    // This will automatically start the oauth flow and redirect to keycloak
    await page.goto('https://catalog.rhdemo.win');
    await expect(page.locator("#kc-page-title")).toBeVisible()

    // Authenticate using environment vars
    await page.getByLabel('Username or email').click();
    await page.getByLabel('Username or email').fill(process.env.catalog_user);
    await page.getByLabel('Username or email').press('Tab');
    await page.getByLabel('Password').fill(process.env.catalog_password);
    await page.getByLabel('Password').press('Enter');

    // Create a portfolio for non production
    await page.getByRole('link', { name: 'Portfolios' }).click();
    await page.locator('body').click();
    await page.getByRole('button', { name: 'Create' }).click();
    await page.locator('input[name="name"]').click();
    await page.locator('input[name="name"]').fill('Middleware non-prod');
    await page.getByLabel('Description').click();
    await page.getByLabel('Description').fill('All products for middleware non-prod environments');
    await page.getByRole('contentinfo').getByRole('button', { name: 'Create' }).click();

    // Create a product for a developer environment
    await page.getByRole('button', { name: 'Add' }).click();
    await page.getByRole('button', { name: 'open menu' }).click();
    await page.getByRole('option', { name: 'Automation Controller' }).click();

    await page.waitForSelector('.pf-c-card');

    await page.evaluate(() => {
        const elements = Array.from(document.querySelectorAll("*"));
        const element = elements.find(el => el.textContent.trim() === 'Development environment');

        if (element) {
            const parent = element.closest(".pf-c-card");
            console.log(parent)
            if (parent) {
                const checkbox = parent.querySelector("input[type='checkbox']");
                if (checkbox) {
                    checkbox.click();
                }
            }
        }
    });

    await page.getByTitle('Add').click();
});
