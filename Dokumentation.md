Ausführliche Systemdokumentation: PDF-OCR Texterkennungsplattform
1. Systemarchitektur und Verarbeitungs-Pipeline
Die PDF-OCR Texterkennung ist eine hochmoderne, Java-basierte Konsolenanwendung, die für die automatisierte, hochperformante und präzise Extraktion von Textebenen aus PDF-Dokumenten konzipiert wurde. Die Anwendung ist speziell für den Betrieb in restriktiven Windows-Unternehmensnetzwerken optimiert. Das System kombiniert robuste Java-Bibliotheken zur Dokumentenanalyse mit der Leistungsfähigkeit der nativen Tesseract OCR (Optical Character Recognition) Engine.

[ PDF-Eingang (input/) ]
           │
           ▼
[ Dokumenten-Analyse (PDFBox) ] ──(Textebene vorhanden?)──► JA ──► [ Direkt-Extraktion ] ──► [ TXT-Ausgabe (output/) ]
           │
          NEIN
           ▼
[ Grafik-Rendering im RAM (300 DPI) ]
           │
           ▼
[ Native Schnittstelle (JNA / Tess4J) ]
           │
           ▼
[ Tesseract OCR-Engine (C++) ] ──(Sprachdaten / tessdata)
           │
           ▼
[ Text-Synthese & Normalisierung ] ──► [ TXT-Ausgabe (output/) ]

Die Verarbeitungs-Schritte im Detail
Schritt 1: Verzeichnisüberwachung und Dateierkennung
Nach dem Systemstart scannt die Anwendung das konfigurierte Eingangsverzeichnis input/ nach gültigen Dateien mit der Endung .pdf. Das System verarbeitet die gefundenen Dokumente sequentiell, um eine Überlastung des Arbeitsspeichers bei sehr großen Dokumenten zu verhindern.

Schritt 2: Intelligente Vorab-Prüfung (Hybrid-Modus)
Vor der rechenintensiven Bildanalyse prüft die Anwendung die interne Struktur der PDF-Datei mithilfe von Apache PDFBox.

Digitale PDFs: Enthält die Datei bereits native, editierbare Textzeichen (wie sie beim direkten Speichern aus Microsoft Word, Excel oder digitalen Berichten entstehen), extrahiert das Programm diesen Textstrom direkt. Dieser Prozess dauert nur Millisekunden, schont die CPU-Ressourcen und garantiert eine fehlerfreie Zeichengenauigkeit von 100 %.

Gescannte PDFs: Enthält das Dokument keine verwertbaren Textzeichen, sondern besteht ausschließlich aus eingebetteten Bildern (typisch für klassische Scanner, Multifunktionsdrucker oder Faxgeräte), schaltet die Anwendung automatisch in den OCR-Modus um.

Schritt 3: Grafik-Rendering und Speicheroptimierung
Um ein bildbasiertes PDF für die Schrifterkennung vorzubereiten, wird jede einzelne Seite des Dokuments im Arbeitsspeicher in ein hochauflösendes, unkomprimiertes Rasterbild gerendert. Standardmäßig verwendet das Programm hierbei eine Auflösung von 300 DPI (Dots Per Inch). Dieser Wert stellt den optimalen Kompromiss zwischen Verarbeitungsgeschwindigkeit und der Erkennungsgenauigkeit von Tesseract dar. Niedrigere Auflösungen führen zu Erkennungsfehlern bei kleinen Schriftarten; höhere Auflösungen steigern den Speicherverbrauch und die CPU-Last exponentiell, ohne die Erkennungsrate signifikant zu verbessern.

Schritt 4: Native Brücke und Zeichenerkennung
Da die eigentliche Schrifterkennungs-Engine Tesseract in hochperformantem C++ geschrieben ist, nutzt das Java-Programm die JNA-Schnittstelle (Java Native Access) über das Framework Tess4J. Das gerenderte Bild wird direkt im Arbeitsspeicher an die native Tesseract-Bibliothek übergeben. Tesseract lädt die für die Erkennung erforderlichen Sprachdaten (z. B. deu.traineddata für Deutsch und eng.traineddata für Englisch) aus dem temporären Verzeichnis und analysiert das Bild Pixel für Pixel. Hierbei werden geometrische Strukturen in Buchstaben, Wörter, Zeilen und Absätze übersetzt.

Schritt 5: Text-Synthese und Ausgabe
Nach dem erfolgreichen Durchlauf aller Seiten führt das Programm die erkannten Textabschnitte im RAM zusammen, bereinigt Zeilenumbrüche, normalisiert Sonderzeichen (wie deutsche Umlaute und das Eszett) und schreibt das Ergebnis als strukturierte Textdatei mit der Endung .txt in das Ausgangsverzeichnis output/. Der Name der Ausgabedatei entspricht dabei exakt dem Namen des ursprünglichen PDF-Dokuments.

2. Infrastruktur und Umgebungskonfiguration
Die Anwendung läuft auf einer isolierten und hochgradig kontrollierten Laufzeitumgebung, um Inkompatibilitäten mit älteren, im System installierten Java-Versionen auszuschließen.

Technische Spezifikationen
Betriebssystem: Windows 11 Enterprise (64-Bit, amd64-Architektur).

Laufzeitumgebung (JRE): OpenJDK 25 in der spezifischen Version jdk-25.0.2+10. Diese Version bringt modernste Performance-Optimierungen für die Speicherverwaltung und native Schnittstellenaufrufe mit.

Build-System: Apache Maven in der Version 3.9.16. Dieses moderne Maven-Release ist zwingend erforderlich, da ältere Maven-Versionen (unter 3.6.3) mit den modernen Build-Plugins und Java 25 inkompatibel sind.

Lokaler Tesseract-Pfad: C:\Program Files\Tesseract-OCR. Dieser Ordner enthält die nativen Windows-DLLs (z. B. libtesseract-5.dll), die für die Ausführung der Schrifterkennung zwingend auf dem System vorhanden sein müssen.

Arbeitsverzeichnis: Das gesamte Projekt befindet sich im lokalen Entwicklungsordner C:\dev\Pdf_OCR.

Dateisystem-Layout
Das Projektverzeichnis ist streng nach den Standards für professionelle Java-Entwicklung strukturiert:

text
C:\dev\Pdf_OCR\
│
├── input\                           # Das Eingangsverzeichnis. Hier werden die zu verarbeitenden PDFs abgelegt.
│
├── output\                          # Das Ausgangsverzeichnis. Hier speichert die App die extrahierten .txt-Dateien.
│
├── target\                          # Das Maven Build-Target. Enthält die kompilierten Klassen und die fertigen Artefakte.
│   ├── classes\                     # Die kompilierten Java-Klassendateien.
│   └── pdf-ocr-1.0-SNAPSHOT.jar     # Das fertige, ausführbare Shaded-JAR ("Fat-JAR").
│
├── pdf-ocr-tmp\                     # Temporärer Laufzeit-Ordner.
│   └── tessdata\                    # Enthält die zur Laufzeit entpackten Sprachdaten (deu.traineddata, eng.traineddata).
│
├── pom.xml                          # Die zentrale XML-Konfigurationsdatei des Maven-Build-Projekts.
│
├── start-windows.bat                # Das Entwicklungs- und Build-Skript (Clean-Build, Dependency-Download, App-Start).
│
└── run_ocr.bat                      # Das Produktiv-Skript (Direktstart der fertigen Anwendung ohne Build-Prozess).
3. Betriebs- und Ausführungssteuerung
Um den Betrieb der Anwendung für Entwickler und Administratoren so einfach und fehlersicher wie möglich zu gestalten, wurde die Ablaufsteuerung vollständig in zwei Windows-Batch-Skripte gekapselt. Beide Skripte setzen temporäre Umgebungsvariablen, die nur für die Dauer der jeweiligen Konsolensitzung gültig sind. Dadurch wird das globale Windows-System nicht beeinflusst.

Das Entwicklungs- und Build-Skript (start-windows.bat)
Dieses Skript wird immer dann ausgeführt, wenn Änderungen am Java-Quellcode vorgenommen wurden oder neue Bibliotheken in der pom.xml hinzugefügt wurden. Es führt einen vollständigen Lebenszyklus-Build (Clean-Build) durch:

Pfad-Validierung: Das Skript prüft physisch, ob Java 25 (c:\dev\jdk\jdk-25.0.2+10) und Maven 3.9.16 (c:\dev\Tools\maven\apache-maven-3.9.16) an den konfigurierten Pfaden existieren. Fehlen diese, bricht das Skript mit einer klaren Fehlermeldung ab.

Umgebungs-Kapselung: Die Variablen JAVA_HOME, MAVEN_HOME und der Systempfad PATH werden temporär mit den Pfaden zu Java 25 und Maven 3.9.16 überschrieben.

SSL-Bypass-Konfiguration: Da das interne Maven-Repository der Signal Iduna (m2repo.system.local) ein unternehmenseigenes SSL-Zertifikat nutzt, das von Standard-Java-Installationen blockiert wird, injiziert das Skript die Variable MAVEN_OPTS. Diese weist die Java Virtual Machine (JVM) an, SSL-Zertifikatsprüfungen und Gültigkeitsdaten während des gesamten Build-Prozesses zu ignorieren:

batch
set MAVEN_OPTS=-Dmaven.wagon.http.ssl.insecure=true -Dmaven.wagon.http.ssl.allowall=true -Dmaven.wagon.http.ssl.ignore.validity.dates=true
Clean & Rebuild: Ein eventuell vorhandenes altes JAR-File wird physisch gelöscht. Anschließend wird der Befehl call %MAVEN_EXEC% clean package ausgeführt. Maven lädt alle Abhängigkeiten sicher herunter, kompiliert den Code und packt das neue Fat-JAR.

Start: Nach erfolgreichem Build startet das Skript die Anwendung mit Java 25.

Das Produktiv- und Schnellstart-Skript (run_ocr.bat)
Dieses Skript ist für den täglichen Einsatz optimiert. Es verzichtet komplett auf den zeitintensiven Maven-Build-Prozess und startet das bereits kompilierte Programm in Millisekunden:

Ressourcenprüfung: Das Skript stellt sicher, dass Java 25 installiert ist und das fertige JAR-File unter target/pdf-ocr-1.0-SNAPSHOT.jar existiert.

Start mit Native Access: Die Anwendung wird direkt über den absoluten Pfad zur java.exe gestartet. Dabei wird ein spezieller JVM-Parameter übergeben:

batch
%JAVA_EXEC% --enable-native-access=ALL-UNNAMED -jar "%JAR_FILE%" %*
Bedeutung des Parameters: Seit neueren Java-Versionen warnt die JVM intensiv vor dem Zugriff auf nativen Maschinencode durch externe Bibliotheken (wie JNA und Tess4J). Ab zukünftigen Java-Versionen wird dieser Zugriff standardmäßig blockiert. Der Parameter --enable-native-access=ALL-UNNAMED erlaubt dem JNA-Framework explizit den uneingeschränkten, performanten Zugriff auf den nativen Tesseract-Code. Dadurch werden lästige Konsolen-Warnungen unterbunden und die Anwendung läuft absolut zukunftssicher unter Java 25.

4. Analyse und Erklärung der Maven-Konfiguration (pom.xml)
Die pom.xml ist das technische Fundament des Projekts. Sie definiert alle Abhängigkeiten, Compiler-Einstellungen und Build-Plugins.

Die Kern-Abhängigkeiten (Dependencies)
Apache PDFBox (pdfbox, v3.0.3): Diese leistungsstarke Bibliothek wird für das Öffnen der PDF-Dokumente, das Extrahieren nativer Textebenen und das pixelgenaue Rendern der PDF-Seiten in hochauflösende Grafiken im Arbeitsspeicher verwendet.

Tess4J (tess4j, v5.12.0): Dies ist das Brücken-Framework (JNA-Wrapper). Es stellt die Java-Schnittstellen bereit, die zur Laufzeit die nativen C++-Funktionen der auf dem Windows-System installierten Tesseract-Engine aufrufen.

SLF4J Simple Logger (slf4j-simple, v2.0.12): SLF4J ist eine weitverbreitete Protokollierungs-Schnittstelle. Ohne eine konkrete Implementierung gibt Java beim Start die Warnung „No SLF4J providers were found“ aus und unterdrückt alle Log-Meldungen. Die Einbindung von slf4j-simple füllt diese Lücke. Sie fängt alle Log-Ausgaben der beteiligten Bibliotheken (wie PDFBox und Tess4J) ab und gibt sie sauber, formatiert und ohne Performanceverluste auf der Windows-Konsole aus.

Die Build-Plugins und das "Shading"-Verfahren
Um die Anwendung als einzelne, portable Datei weiterzugeben, wird das Maven Shade Plugin in der Version 3.5.3 eingesetzt. Dieses entpackt beim Kompilieren alle Klassen und Ressourcen aus den JAR-Dateien der Abhängigkeiten (PDFBox, Tess4J, JNA, SLF4J) und fügt sie zusammen mit Ihrem eigenen Code in eine einzige, große JAR-Datei (pdf-ocr-1.0-SNAPSHOT.jar) zusammen.

Um dabei Konflikte und Warnungen zu vermeiden, enthält die Konfiguration zwei wichtige Mechanismen:

Der Metadaten- und Signaturfilter:
Viele Bibliotheken bringen eigene Manifestdateien (MANIFEST.MF), Lizenzen (LICENSE.txt, NOTICE) oder kryptografische Signaturen (*.SF, *.DSA, *.RSA) mit. Würden diese ungefiltert in das Ziel-JAR kopiert, würden sie sich gegenseitig überschreiben, was zu massiven Build-Warnungen und im schlimmsten Fall zu Sicherheitsabstürzen der JVM führt (da die Signaturen einzelner Klassen nach dem Umpacken ungültig werden). Der Filter bereinigt das JAR beim Packen automatisch:

XML
<filter>
    <artifact>*</artifact>
    <excludes>
        <exclude>META-INF/*.SF</exclude>
        <exclude>META-INF/*.DSA</exclude>
        <exclude>META-INF/*.RSA</exclude>
        <exclude>META-INF/LICENSE*</exclude>
        <exclude>META-INF/NOTICE*</exclude>
        <exclude>META-INF/DEPENDENCIES</exclude>
        <exclude>META-INF/manifest.mf</exclude>
    </excludes>
</filter>
Der ServicesResourceTransformer:
Einige Java-Bibliotheken registrieren ihre internen Treiber (Spi-Provider) in Konfigurationsdateien unter META-INF/services/. Ohne diesen Transformer würde die letzte gepackte Bibliothek die Service-Dateien der vorherigen Bibliotheken überschreiben, wodurch z. B. wichtige Bild-Reader für PDFBox verloren gingen. Der Transformer liest diese Dateien während des Builds aus, führt ihren Inhalt intelligent zusammen und schreibt eine gemeinsame Datei in das fertige Shaded-JAR.

5. Diagnose-Interpretation und Fehlerbehebung (Troubleshooting)
Dieses Kapitel dient als praktischer Leitfaden für Systemadministratoren und Entwickler zur Interpretation von Konsolenmeldungen und zur schnellen Behebung von Fehlerszenarien.

Interpretation von Standard-Konsolenmeldungen
Estimating resolution as XXXX

Bedeutung: Dies ist eine rein informative Meldung der Tesseract-Engine. Sie tritt auf, wenn ein gescanntes PDF-Dokument keine Metadaten über die DPI-Auflösung enthält, mit der es damals eingescannt wurde. Tesseract schätzt (approximiert) die Auflösung dann anhand der durchschnittlichen Höhe der erkannten Buchstaben auf der Seite.

Aktion: Keine. Dies ist ein völlig normaler, interner Optimierungsschritt der OCR-Engine und hat keinen negativen Einfluss auf die Qualität der Erkennung.

SLF4J(W): No SLF4J providers were found.

Bedeutung: Dieser Hinweis zeigt an, dass die Anwendung versucht, Protokollmeldungen auszugeben, aber keine konkrete Logging-Bibliothek im Klassenpfad gefunden wurde.

Behebung: Stellen Sie sicher, dass die Abhängigkeit slf4j-simple in der pom.xml eingetragen ist und das Projekt danach mit der start-windows.bat neu gebaut wurde, damit die Bibliothek in das Shaded-JAR integriert wird.

Bekannte Fehlerszenarien und deren Behebung
1. Fehler: SunCertPathBuilderException: unable to find valid certification path
Symptom: Der Maven-Build bricht beim Herunterladen von Abhängigkeiten sofort ab.

Ursache: Das firmeninterne Maven-Repository der Signal Iduna nutzt ein SSL-Zertifikat einer internen Zertifizierungsstelle (CA). Die Standard-Java-Installation kennt diese CA nicht und blockiert die Verbindung aus Sicherheitsgründen.

Behebung:

Verwenden Sie zum Bauen immer die start-windows.bat. Diese setzt die Variable MAVEN_OPTS mit den Parametern -Dmaven.wagon.http.ssl.insecure=true -Dmaven.wagon.http.ssl.allowall=true, wodurch Maven angewiesen wird, die Gültigkeit des Zertifikats zu ignorieren.

Alternativ können Sie das Zertifikat der Signal Iduna CA dauerhaft in den Keystore von Java 25 importieren. Führen Sie dazu folgenden Befehl in einer administrativen CMD aus:

cmd
"c:\dev\jdk\jdk-25.0.2+10\bin\keytool.exe" -importcert -alias "signaliduna-repo" -file "C:\Pfad\zu\signaliduna-ca.cer" -keystore "c:\dev\jdk\jdk-25.0.2+10\lib\security\cacerts" -storepass changeit -noprompt
2. Fehler: java.lang.NoClassDefFoundError: net/sourceforge/tess4j/ITesseract
Symptom: Die Anwendung stürzt beim Starten sofort ab.

Ursache: Das Programm versucht, Klassen aus der Tess4J-Bibliothek zu laden, findet diese aber nicht im Klassenpfad. Dies passiert, wenn die JAR-Datei im target/-Ordner nicht über das Shade-Plugin gebündelt wurde (z. B. weil der vorherige Build-Prozess mit einem Fehler abgebrochen ist).

Behebung: Starten Sie die start-windows.bat und stellen Sie sicher, dass der Build-Prozess am Ende die Meldung [INFO] BUILD SUCCESS ausgibt. Löschen Sie manuell eventuell verbliebene, fehlerhafte JAR-Dateien im Ordner target/ vor dem Rebuild.

3. Fehler: CommandNotFoundException beim Ausführen des Download-Skripts
Symptom: Das PowerShell-Skript zum Herunterladen der Tesseract-DLLs bricht mit der Meldung ab, dass 7za.exe nicht gefunden wurde.

Ursache: Das Skript hat das temporäre Verzeichnis bereinigt und dabei die zuvor heruntergeladene portable Version von 7-Zip gelöscht, bevor der Entpackungsvorgang der Tesseract-Installer gestartet wurde.

Behebung: Nutzen Sie die korrigierte Version des Download-Skripts, bei der die Ordnerbereinigung und -erstellung an den absoluten Anfang des Skripts verlegt wurde, sodass benötigte Hilfswerkzeuge während der gesamten Laufzeit des Skripts erhalten bleiben.