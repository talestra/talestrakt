import java.awt.Desktop
import java.awt.event.MouseEvent
import java.io.File
import java.net.URI
import java.util.prefs.Preferences
import javax.imageio.ImageIO
import javax.swing.JFileChooser
import javax.swing.JFrame
import javax.swing.JOptionPane
import javax.swing.UIManager
import javax.swing.event.MouseInputAdapter
import javax.swing.filechooser.FileFilter

fun main(args: Array<String>) {
	UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName())
	val frame = JFrame("Yume Miru Kusuri en español")
	val icon = ImageIO.read(ClassLoader.getSystemResource("patcher_ico.png"))
	val form = YumeMiruPatcher()
	frame.iconImage = icon
	frame.isResizable = false
	frame.contentPane = form.patchpanel
	frame.defaultCloseOperation = JFrame.EXIT_ON_CLOSE
	frame.pack()
	frame.setLocationRelativeTo(null)
	frame.isVisible = true

	form.website.addMouseListener(object : MouseInputAdapter() {
		override fun mouseClicked(e: MouseEvent?) {
			val desktop = Desktop.getDesktop()
			desktop.browse(URI("http://yume.tales-tra.com/"))
		}
	})

	form.patch.addMouseListener(object : MouseInputAdapter() {
		override fun mouseClicked(e: MouseEvent?) {
			val prefs = Preferences.userRoot().node(javaClass.name)
			val LAST_USED_FOLDER = "LAST_USED_FOLDER"

			val fc = JFileChooser();

			fc.currentDirectory = File(prefs.get(LAST_USED_FOLDER, "."))

			fc.fileFilter = object : FileFilter() {
				override fun getDescription(): String = "yumemiru.exe"

				override fun accept(pathname: File): Boolean {
					return pathname.isDirectory || pathname.name == "yumemiru.exe"
				}
			}
			val returnVal = fc.showOpenDialog(frame);

			if (fc.selectedFile != null) {
				prefs.put(LAST_USED_FOLDER, fc.selectedFile.parent);

				JOptionPane.showMessageDialog(null, "Selected file: ${fc.selectedFile}, returnVal = $returnVal");
			}
		}
	})
}