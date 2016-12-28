package com.talestra.yume.patcher

import java.awt.Desktop
import java.awt.event.MouseEvent
import java.io.File
import java.net.URI
import java.util.prefs.Preferences
import javax.imageio.ImageIO
import javax.swing.*
import javax.swing.event.MouseInputAdapter
import javax.swing.filechooser.FileFilter

const val VERSION = "v1.0"

object YumeMiruPatcher {
	@JvmStatic fun main(args: Array<String>) {
		UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName())
		//UIManager.setLookAndFeel(MetalLookAndFeel())
		//UIManager.setLookAndFeel(MotifLookAndFeel())
		//UIManager.setLookAndFeel(NimbusLookAndFeel())


		val frame = JFrame("Yume Miru Kusuri en español - $VERSION")
		val icon = ImageIO.read(ClassLoader.getSystemResource("patcher_ico.png"))
		val form = object {
			val patchpanel = JPanel()
			val image = JLabel().apply {
				this.icon = ImageIcon(ImageIO.read(getResource("data/bg.jpg")))
			}
			val patch = JButton().apply {
				text = "Parchear"
			}
			val website = JButton().apply {
				text = "Página web..."
			}

			init {
				patchpanel.layout = null
				patchpanel.add(patch)
				patchpanel.add(website)
				patchpanel.add(image)

				image.setBounds(0, 0, 640, 480)
				patch.setBounds(400, 360, 200, 32)
				website.setBounds(400, 400, 200, 32)

			}
		}
		frame.iconImage = icon
		frame.isResizable = false
		frame.contentPane = form.patchpanel
		frame.defaultCloseOperation = JFrame.EXIT_ON_CLOSE
		frame.setSize(640, 480)
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

				val fc = JFileChooser()

				fc.currentDirectory = File(prefs.get(LAST_USED_FOLDER, "."))

				fc.fileFilter = object : FileFilter() {
					override fun getDescription(): String = "yumemiru.exe"

					override fun accept(pathname: File): Boolean {
						return pathname.isDirectory || pathname.name == "yumemiru.exe"
					}
				}
				val returnVal = fc.showOpenDialog(frame)

				if (fc.selectedFile != null) {
					prefs.put(LAST_USED_FOLDER, fc.selectedFile.parent)

					JOptionPane.showMessageDialog(null, "Selected file: ${fc.selectedFile}, returnVal = $returnVal")
				}
			}
		})
	}
}