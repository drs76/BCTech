/// <summary>
/// ControlAddIn PTEBCFTPFileContent
/// </summary>
controladdin PTEBCFTPFileContent
{
    MinimumWidth = 250;
    MinimumHeight = 250;
    RequestedHeight = 600;
    RequestedWidth = 400;
    VerticalStretch = true;
    VerticalShrink = true;
    HorizontalStretch = true;
    HorizontalShrink = true;
    Scripts = 'src/controladdins/FileContent/scripts/fileContent.js';
    StartupScript = 'src/controladdins/FileContent/scripts/fileContentStart.js';

    /// <summary>
    /// ControlReady.
    /// </summary>
    event ControlReady();

    /// <summary>
    /// Init.
    /// </summary>
    procedure Init();

    /// <summary>
    /// Load.
    /// </summary>
    /// <param name="data">Text.</param>
    procedure Load(data: Text);
}