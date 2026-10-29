# Unicode Fonts for Invoice PDF Generation

This directory contains TrueType (TTF) fonts used by the Invoice PDF Generator to render:
- English, numbers, and general punctuation (Noto Sans)
- Indian Rupee symbol `₹` (Unicode U+20B9)
- Marathi / Hindi text with Devanagari script (Noto Sans Devanagari)

## Required Font Files
1. `NotoSans-Regular.ttf`
2. `NotoSans-Bold.ttf`
3. `NotoSansDevanagari-Regular.ttf`
4. `NotoSansDevanagari-Bold.ttf`

## Automatic Setup
Run the following Dart command from the project root:
```bash
dart run tool/setup_fonts.dart
```

## Manual Download URLs
If downloading manually, save the files to this `assets/fonts/` directory:
- **NotoSans-Regular.ttf**: https://fonts.gstatic.com/s/notosans/v36/o-0mIpQlx3QUlC5A4PNB6Ryti20_6n1iPHjcz6L1SoM-jCpoiyD9A99d41P6zHtY.ttf
- **NotoSans-Bold.ttf**: https://fonts.gstatic.com/s/notosans/v36/o-0mIpQlx3QUlC5A4PNB6Ryti20_6n1iPHjcz6L1SoM-jCpoiyAaBN9d41P6zHtY.ttf
- **NotoSansDevanagari-Regular.ttf**: https://fonts.gstatic.com/s/notosansdevanagari/v26/TuGoUUFzXI5FBtUq5a8bjKYTZjtRU6Sgv3NaV_SNmI0b8QQCQmHn6B2OHjbL_08AlXQly-AzoFoW4Ow.ttf
- **NotoSansDevanagari-Bold.ttf**: https://fonts.gstatic.com/s/notosansdevanagari/v26/TuGoUUFzXI5FBtUq5a8bjKYTZjtRU6Sgv3NaV_SNmI0b8QQCQmHn6B2OHjbL_08AlZMiy-AzoFoW4Ow.ttf

Note: If running with internet access on the first launch, `InvoicePdfFontLoader` can also download and cache these fonts automatically using `PdfGoogleFonts`.
